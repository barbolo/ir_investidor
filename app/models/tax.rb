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

  def calculated_aliquots
    calculated_values[:aliquots]
  end

  def calculated_net_earnings
    calculated_values[:net_earnings]
  end

  def calculated_losses
    calculated_values[:losses]
  end

  def stocks_tax_free?
    Asset::Stock.tax_free?(stock_sales)
  end

  private
    def calculated_values
      return @calculated_values if @calculated_values
      @calculated_values = {}
      @calculated_values[:taxes_stocks] = 0
      @calculated_values[:darf] = 0
      @calculated_values[:irrf] = 0
      @calculated_values[:irrf_compensated] = 0
      @calculated_values[:aliquots] = {
        non_daytrade: 0.15,
        daytrade:     0.20,
        fii:          Asset::Fii.tax_aliquot,
      }
      @calculated_values[:net_earnings] = {
        non_daytrade: 0,
        daytrade:     0,
        fii:          0,
      }
      @calculated_values[:losses] = {
        non_daytrade: 0,
        daytrade:     0,
        fii:          0,
      }

      tax_entries.each do |entry|
        if entry.asset == Transaction::ASSET['fii']
          @calculated_values[:net_earnings][:fii] += entry.net_earning
        elsif entry.daytrade
          @calculated_values[:net_earnings][:daytrade] += entry.net_earning
        else
          @calculated_values[:net_earnings][:non_daytrade] += entry.net_earning
        end

        if entry.asset == Transaction::ASSET['stock'] && !entry.daytrade
          @calculated_values[:taxes_stocks] += entry.net_earning * entry.aliquot
        end

        @calculated_values[:irrf] += entry.irrf
      end

      @calculated_values[:losses][:non_daytrade] = losses_accumulated
      @calculated_values[:losses][:daytrade]     = losses_accumulated_day_trade
      @calculated_values[:losses][:fii]          = losses_accumulated_fii

      # non daytrade
      aliquot      = @calculated_values[:aliquots][:non_daytrade]
      net_earnings = @calculated_values[:net_earnings][:non_daytrade]
      losses       = @calculated_values[:losses][:non_daytrade]
      @calculated_values[:darf] += aliquot * [net_earnings - losses, 0].max

      if @calculated_values[:taxes_stocks] < 0
        @calculated_values[:taxes_stocks] = 0
      end

      if stocks_tax_free?
        @calculated_values[:darf] -= @calculated_values[:taxes_stocks]
        @calculated_values[:darf] = [@calculated_values[:darf], 0].max
      end

      # daytrade
      aliquot      = @calculated_values[:aliquots][:daytrade]
      net_earnings = @calculated_values[:net_earnings][:daytrade]
      losses       = @calculated_values[:losses][:daytrade]
      @calculated_values[:darf] += aliquot * [net_earnings - losses, 0].max

      # fii
      aliquot      = @calculated_values[:aliquots][:fii]
      net_earnings = @calculated_values[:net_earnings][:fii]
      losses       = @calculated_values[:losses][:fii]
      @calculated_values[:darf] += aliquot * [net_earnings - losses, 0].max

      irrf_sum = irrf_accumulated_to_compensate + @calculated_values[:irrf]
      irrf_compensated = [@calculated_values[:darf], irrf_sum].min
      irrf_compensated = 0 if irrf_compensated < 0
      @calculated_values[:irrf_compensated] = irrf_compensated
      @calculated_values[:darf] -= irrf_compensated

      @calculated_values[:darf] = 0 if @calculated_values[:darf] < 0

      @calculated_values
    end
end
