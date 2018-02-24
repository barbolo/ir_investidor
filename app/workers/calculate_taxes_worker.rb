class CalculateTaxesWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'calculating'
  def perform(user_id, start_date = nil)
    user = User.find(user_id)

    user.tax_for(Date.today) # ensure a tax for the current date exists

    taxes = user.taxes.includes(:tax_entries).order(:period)
    if start_date
      start_date = start_date.beginning_of_month
      if start_date == Date.today.beginning_of_month
        start_date = start_date - 1.month
      end
      taxes = taxes.where('period >= ?', start_date)
    end

    # check if a tax exists for each period (month)
    created_tax = false
    previous_tax_period = nil
    taxes.each do |tax|
      if previous_tax_period && (tax.period - previous_tax_period) > 31
        # create tax for the month that has not tax
        previous_tax_period = user.tax_for(previous_tax_period + 1.month).period
        created_tax = true
        redo
      end
      previous_tax_period = tax.period
    end
    fail('Should run again because taxes were created') if created_tax

    # calculate taxes
    previous_tax = nil
    taxes.each do |tax|
      # update references from previous tax before calculating current tax
      if previous_tax
        losses_accumulated = previous_tax.losses_accumulated - previous_tax.net_earnings
        losses_accumulated = 0 if losses_accumulated < 0
        losses_accumulated_day_trade = previous_tax.losses_accumulated_day_trade - previous_tax.net_earnings_day_trade
        losses_accumulated_day_trade = 0 if losses_accumulated_day_trade < 0
        losses_accumulated_fii = previous_tax.losses_accumulated_fii - previous_tax.net_earnings_fii
        losses_accumulated_fii = 0 if losses_accumulated_fii < 0

        irrf_accumulated_to_compensate = previous_tax.irrf + previous_tax.irrf_accumulated_to_compensate
        irrf_accumulated_to_compensate -= previous_tax.calculated_irrf_compensated

        tax.losses_accumulated = losses_accumulated
        tax.losses_accumulated_day_trade = losses_accumulated_day_trade
        tax.losses_accumulated_fii = losses_accumulated_fii
        tax.irrf_accumulated_to_compensate = irrf_accumulated_to_compensate
      end

      tax.net_earnings = tax.calculated_net_earnings[:non_daytrade]
      tax.net_earnings_day_trade = tax.calculated_net_earnings[:daytrade]
      tax.net_earnings_fii = tax.calculated_net_earnings[:fii]
      tax.irrf = tax.calculated_irrf

      tax.stock_sales = user.transactions
                        .where(operation: Transaction::OPERATION['sell'])
                        .where(asset: Transaction::ASSET['stock'])
                        .where(operation_at: tax.period..tax.period.end_of_month)
                        .sum(:value)

      tax.darf = tax.calculated_darf

      tax.save!
      tax.reload
      previous_tax = tax
    end
  end
end
