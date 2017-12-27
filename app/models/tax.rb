class Tax < ApplicationRecord
  belongs_to :user
  has_many :tax_entries, -> { order 'operation_at ASC' }, dependent: :destroy

  def calculated_net_earnings
    calculated_values[:net_earnings]
  end

  def calculated_net_earnings_daytrade
    calculated_values[:net_earnings_daytrade]
  end

  def calculated_taxes_stocks
    calculated_values[:taxes_stocks]
  end

  def calculated_darf
    calculated_values[:darf]
  end

  def calculated_irrf
    calculated_values[:irrf]
  end

  def calculated_irrf_compensated
    calculated_values[:irrf_compensated]
  end

  def calculated_aliquots_values
    calculated_values[:aliquots_values]
  end

  def calculated_aliquots_losses
    calculated_values[:aliquots_losses]
  end

  def stocks_tax_free?
    Asset::Stock.tax_free?(stock_sales)
  end

  private
    def calculated_values
      return @calculated_values if @calculated_valuesi
      @calculated_values = {}
      @calculated_values[:net_earnings] = 0
      @calculated_values[:net_earnings_daytrade] = 0
      @calculated_values[:taxes_stocks] = 0
      @calculated_values[:darf] = 0
      @calculated_values[:irrf] = 0
      @calculated_values[:irrf_compensated] = 0
      @calculated_values[:aliquots_values] = {}
      @calculated_values[:aliquots_losses] = {}

      tax_entries.each do |entry|
        if entry.daytrade
          @calculated_values[:net_earnings_daytrade] += entry.net_earning
        else
          @calculated_values[:net_earnings] += entry.net_earning
        end

        if entry.asset == Transaction::ASSET['stock'] && !entry.daytrade
          @calculated_values[:taxes_stocks] += entry.net_earning * entry.aliquot
        end

        @calculated_values[:irrf] += entry.irrf

        @calculated_values[:aliquots_values][entry.aliquot] ||= 0
        @calculated_values[:aliquots_values][entry.aliquot] += entry.net_earning
      end

      @calculated_values[:aliquots_losses][BigDecimal.new('0.15')] = losses_accumulated
      @calculated_values[:aliquots_losses][BigDecimal.new('0.20')] = losses_accumulated_day_trade

      @calculated_values[:aliquots_values].each do |aliquot, net_earnings|
        losses = @calculated_values[:aliquots_losses][aliquot] || 0
        earnings = [net_earnings - losses, 0].max
        @calculated_values[:darf] += aliquot * earnings
      end

      if @calculated_values[:taxes_stocks] < 0
        @calculated_values[:taxes_stocks] = 0
      end

      if stocks_tax_free?
        @calculated_values[:darf] -= @calculated_values[:taxes_stocks]
      end

      irrf_sum = irrf_accumulated_to_compensate + @calculated_values[:irrf]
      irrf_compensated = [@calculated_values[:darf], irrf_sum].min
      irrf_compensated = 0 if irrf_compensated < 0
      @calculated_values[:irrf_compensated] = irrf_compensated
      @calculated_values[:darf] -= irrf_compensated

      @calculated_values[:darf] = 0 if @calculated_values[:darf] < 0

      @calculated_values
    end
end
