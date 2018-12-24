class TaxCalculator
  TAX_ALIQUOT = {
    'common'   => BigDecimal('0.15'),
    'daytrade' => BigDecimal('0.20'),
    'fii'      => BigDecimal('0.20'),
  }

  IRRF_ALIQUOT = {
    'common'   => BigDecimal('0.00005'),
    'daytrade' => BigDecimal('0.01'),
  }

  attr_accessor :session, :trades, :logs, :taxes

  def initialize(session, trades)
    self.session = session
    self.trades  = {}
    self.logs    = []
    self.taxes   = {}
  end

  def add_entry(order, asset)
    tax, common_daytrade = tax_for(order, asset)

    entry = {}
    entry['name'] = order.name
    entry['tax_aliquot']  = (order.asset_class == Asset::TYPE['fii'] ? TAX_ALIQUOT['fii'] : TAX_ALIQUOT[common_daytrade])
    entry['irrf_aliquot'] = IRRF_ALIQUOT[common_daytrade]

    # calculate earnings and irrf
    if order.order_type == Order::TYPE['venda']
      entry['earnings'] = [order.quantity, asset['quantity']].min * (order.price_considering_costs - asset['price'])
      entry['irrf']     = order.price * order.quantity * entry['irrf_aliquot']
    elsif order.order_type == Order::TYPE['compra']
      entry['earnings'] = [order.quantity, asset['quantity'].abs].min * (asset['price'] - order.price_considering_costs)
      entry['irrf']     = 0
    end

    # calculate tax due
    entry['tax_due']      = (entry['earnings'] > 0 ? entry['earnings'] * entry['tax_aliquot'] : 0)
    entry['disposed_at']  = order.ordered_at

    # generate logs
    if (entry['irrf'] - order.irrf).abs > 0.01
      logs << "Linha #{order.row}. IRRF informado: #{order.irrf.round(2)}. IRRF calculado: #{entry['irrf'].round(2)}. Calculamos os impostos com o IRRF calculado."
    end

    # save tax entry
    tax['earnings'] += entry['earnings']
    tax['entries']  << entry
  end

  def add_trade(order)
    key = trade_key(order)
    trades[key] ||= 0
    trades[key] += order.quantity
  end

  def trade_key(order, order_type = nil)
    "#{order_type || order.order_type}-#{order.asset_class}-#{order.name}-#{order.ordered_at}"
  end

  def calculate_and_save
    accumulated = {
      'common'   => 0,
      'daytrade' => 0,
      'fii'      => 0,
      'irrf'     => 0,
    }

    taxes.sort_by { |period, _| period }.each do |period, tax_period|
      acao       = tax_period[Asset::TYPE['acao']]
      opcao      = tax_period[Asset::TYPE['opcao']]
      fii        = tax_period[Asset::TYPE['fii']]
      subscricao = tax_period[Asset::TYPE['subscricao']]

      tax = Tax.new
      tax.session_id            = session.id
      tax.period                = period
      tax.common_tax_aliquot    = TAX_ALIQUOT['common']
      tax.common_irrf_aliquot   = IRRF_ALIQUOT['common']
      tax.daytrade_tax_aliquot  = TAX_ALIQUOT['daytrade']
      tax.daytrade_irrf_aliquot = IRRF_ALIQUOT['daytrade']
      tax.fii_tax_aliquot       = TAX_ALIQUOT['fii']

      # "Ganhos líquidos em operações no mercado à vista de ações negociadas em
      #  bolsa de valores nas alienações realizadas até R$ 20.000, em cada mês,
      #  para o conjunto de ações"
      tax.stocks_sales = acao['common']['sales'] + acao['daytrade']['sales']
      if tax.stocks_sales <= 20_000 && acao['common']['earnings'] > 0
        tax.stocks_taxfree_profits = acao['common']['earnings']
        acao['common']['earnings'] = 0
      else
        tax.stocks_taxfree_profits = 0
      end

      # OPERAÇÕES COMUNS
      tax.common_stocks_earnings        = acao['common']['earnings']
      tax.common_options_earnings       = opcao['common']['earnings']
      tax.common_subscriptions_earnings = subscricao['common']['earnings']
      tax.common_earnings         = tax.common_stocks_earnings + tax.common_options_earnings + tax.common_subscriptions_earnings
      tax.common_sales            = acao['common']['sales'] + opcao['common']['sales'] + subscricao['common']['sales']
      tax.common_irrf             = tax.common_sales * tax.common_irrf_aliquot
      tax.common_losses_before    = accumulated['common']
      tax.common_taxable_value    = tax.common_earnings - tax.common_losses_before
      if tax.common_taxable_value < 0
        tax.common_losses_after   = - tax.common_taxable_value
        tax.common_taxable_value  = 0
        tax.common_tax_due        = 0
      else
        tax.common_losses_after   = 0
        tax.common_tax_due        = tax.common_taxable_value * tax.common_tax_aliquot
      end
      accumulated['common']       = tax.common_losses_after

      # OPERAÇÕES DAY-TRADE
      tax.daytrade_stocks_earnings  = acao['daytrade']['earnings']
      tax.daytrade_options_earnings = opcao['daytrade']['earnings']
      tax.daytrade_earnings         = tax.daytrade_stocks_earnings + tax.daytrade_options_earnings
      tax.daytrade_sales            = acao['daytrade']['sales'] + opcao['daytrade']['sales']
      tax.daytrade_irrf             = tax.daytrade_sales * tax.daytrade_irrf_aliquot
      tax.daytrade_losses_before    = accumulated['daytrade']
      tax.daytrade_taxable_value    = tax.daytrade_earnings - tax.daytrade_losses_before
      if tax.daytrade_taxable_value < 0
        tax.daytrade_losses_after   = - tax.daytrade_taxable_value
        tax.daytrade_taxable_value  = 0
        tax.daytrade_tax_due        = 0
      else
        tax.daytrade_losses_after   = 0
        tax.daytrade_tax_due        = tax.daytrade_taxable_value * tax.daytrade_tax_aliquot
      end
      accumulated['daytrade']       = tax.daytrade_losses_after

      # FII
      tax.fii_earnings         = fii['common']['earnings'] + fii['daytrade']['earnings']
      tax.fii_sales            = fii['common']['sales'] + fii['daytrade']['sales']
      tax.fii_irrf             = fii['common']['sales'] * tax.common_irrf_aliquot + fii['daytrade']['sales'] * tax.daytrade_irrf_aliquot
      tax.fii_losses_before    = accumulated['fii']
      tax.fii_taxable_value    = tax.fii_earnings - tax.fii_losses_before
      if tax.fii_taxable_value < 0
        tax.fii_losses_after   = - tax.fii_taxable_value
        tax.fii_taxable_value  = 0
        tax.fii_tax_due        = 0
      else
        tax.fii_losses_after   = 0
        tax.fii_tax_due        = tax.fii_taxable_value * tax.fii_tax_aliquot
      end
      accumulated['fii']       = tax.fii_losses_after

      # TOTAL
      tax.tax_due      = tax.common_tax_due + tax.daytrade_tax_due + tax.fii_tax_due
      tax.irrf         = tax.common_irrf + tax.daytrade_irrf + tax.fii_irrf
      tax.irrf_before  = accumulated['irrf']
      accumulated_irrf = tax.irrf + tax.irrf_before
      if tax.tax_due > 0
        irrf_discount  = [accumulated_irrf, tax.tax_due].min
        tax.irrf_after = accumulated_irrf - irrf_discount
        tax.darf       = tax.tax_due - irrf_discount
      else
        tax.irrf_after = accumulated_irrf
        tax.darf = 0
      end
      accumulated['irrf'] = tax.irrf_after

      tax.save!

      tax_period.each do |asset_class, tax_common_daytrade|
        tax_common_daytrade.each do |common_daytrade, t|
          t['entries'].each do |entry|
            TaxEntry.create!(entry.merge(
              'tax_id'      => tax.id,
              'asset_class' => asset_class,
              'daytrade'    => (common_daytrade == 'daytrade'),
            ))
          end
        end
      end
    end
  end

  def tax_for(order, asset)
    period = order.ordered_at.beginning_of_month
    asset_class = order.asset_class
    common_daytrade = order.daytrade? ? 'daytrade' : 'common'
    common_daytrade_expected = case order.order_type
                               when Order::TYPE['compra']
                                 trades[trade_key(order, Order::TYPE['venda'])].to_i > 0 ? 'daytrade' : 'common'
                               when Order::TYPE['venda']
                                 trades[trade_key(order, Order::TYPE['compra'])].to_i > 0 ? 'daytrade' : 'common'
                               end

    if common_daytrade != common_daytrade_expected
      if common_daytrade_expected == 'daytrade'
        logs << "Linha #{order.row}. Acreditamos que a operação seja day trade (DAYTRADE = S), mas os impostos foram calculados como se ela fosse comum."
      else
        logs << "Linha #{order.row}. Acreditamos que a operação seja comum (DAYTRADE = N), mas os impostos foram calculados como se ela fosse day trade."
      end
    end

    if taxes[period].nil?
      taxes[period] = {}
      Asset::TYPE.values.each do |asset_class|
        taxes[period][asset_class] = {
          'common'   => {'earnings' => 0, 'sales' => 0, 'entries' => []},
          'daytrade' => {'earnings' => 0, 'sales' => 0, 'entries' => []},
        }
      end
    end
    [taxes[period][asset_class][common_daytrade], common_daytrade]
  end
end
