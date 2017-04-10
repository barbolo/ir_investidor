class Tax < ApplicationRecord
  belongs_to :user
  has_many :tax_entries, -> { order 'operation_at ASC' }, dependent: :destroy

  def calculated_net_earnings
    calculated_values[:net_earnings]
  end

  def calculated_net_earnings_daytrade
    calculated_values[:net_earnings_daytrade]
  end

  def calculated_darf
    calculated_values[:darf]
  end

  def calculated_irrf
    calculated_values[:irrf]
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

      aliquots_values = {}
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

        aliquots_values[entry.aliquot] ||= 0
        aliquots_values[entry.aliquot] += entry.net_earning
      end

      aliquots_values.each do |aliquot, net_earnings|
        if net_earnings > 0
          @calculated_values[:darf] += aliquot * net_earnings
        end
      end

      if stocks_tax_free?
        @calculated_values[:darf] -= @calculated_values[:taxes_stocks]
      end

      @calculated_values[:darf] -= @calculated_values[:irrf]
      @calculated_values[:darf] -= irrf_accumulated_to_compensate

      @calculated_values[:darf] = 0 if @calculated_values[:darf] < 0

      @calculated_values
    end
end
