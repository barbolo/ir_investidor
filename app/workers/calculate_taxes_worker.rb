class CalculateTaxesWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'calculating'
  def perform(user_id, start_date = nil)
    user = User.find(user_id)

    taxes = user.taxes.includes(:tax_entries).order(:period)
    if start_date
      taxes = taxes.where('period >= ?', start_date.beginning_of_month)
    end

    previous_tax = nil
    taxes.each do |tax|
      tax.net_earnings = tax.calculated_net_earnings
      tax.net_earnings_day_trade = tax.calculated_net_earnings_daytrade
      tax.irrf = tax.calculated_irrf

      tax.stock_sales = user.transactions
                        .where(operation: Transaction::OPERATION['sell'])
                        .where(asset: Transaction::ASSET['stock'])
                        .where(operation_at: tax.period..tax.period.end_of_month)
                        .sum(:value)

      tax.darf = tax.calculated_darf
      if previous_tax
        if previous_tax.net_earnings < 0
          tax.losses_accumulated = previous_tax.net_earnings
        end
        if previous_tax.calculated_net_earnings_daytrade < 0
          tax.losses_accumulated_day_trade = previous_tax.calculated_net_earnings_daytrade
        end
        if previous_tax.darf == 0
          tax.irrf_accumulated_to_compensate = previous_tax.irrf + previous_tax.irrf_accumulated_to_compensate
        end
      end
      tax.save!
      tax.reload
      previous_tax = tax
    end
  end
end
