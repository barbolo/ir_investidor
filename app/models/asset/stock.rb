# References:
# http://www.bmfbovespa.com.br/pt_br/servicos/tarifas/listados-a-vista-e-derivativos/renda-variavel/tarifas-de-acoes-e-fundos-de-investimento/a-vista/
class Asset::Stock < Asset::Base
  def self.costs(transaction)
    items = {}
    if transaction.daytrade?
      items['Corretagem'] = BigDecimal.new('1.99')
      items['Corretagem - ISS (5%)'] = (BigDecimal.new('1.99') * 0.05).floor(2)
      items['Emolumentos/Negociação (0,005%)'] = (transaction.value * 0.000050).floor(2)
      items['Liquidação (0,0200%)'] = (transaction.value * 0.0002).floor(2)
    else
      items['Corretagem'] = BigDecimal.new('1.99')
      items['Corretagem - ISS (5%)'] = (BigDecimal.new('1.99') * 0.05).floor(2)
      items['Emolumentos/Negociação (0,005%)'] = (transaction.value * 0.000050).floor(2)
      items['Liquidação (0,0275%)'] = (transaction.value * 0.000275).floor(2)
    end
    items
  end

  def self.irrf(transaction)
    if transaction.inverse_holding.present?
      if transaction.daytrade?
        (transaction.net_earnings * 0.01).floor(2)
      else
        (transaction.net_earnings * 0.00005).floor(2)
      end
    else
      0
    end
  end

  def self.add_tax_entry(transaction)
    net_earnings = transaction.net_earnings
    daytrade = transaction.daytrade?
    irrf = transaction.irrf
    aliquot = tax_aliquot(transaction)

    if !daytrade
      # Update stock sales in tax for current month
      tax_operation = transaction.user.tax_for(transaction.operation_at)
      tax_operation.stock_sales += transaction.value
      tax_operation.save!
    end

    # Update taxes
    tax = transaction.user.tax_for(transaction.settlement_at)
    if daytrade
      tax.net_earnings_day_trade += net_earnings
    else
      tax.net_earnings += net_earnings
    end
    tax_entry = tax.tax_entries.build
    tax_entry.asset = transaction.asset
    tax_entry.asset_name = transaction.asset_name
    tax_entry.daytrade = daytrade
    tax_entry.net_earning = net_earnings
    tax_entry.aliquot = aliquot
    if net_earnings > 0
      tax.irrf += irrf
      tax_entry.tax_value = aliquot * net_earnings
      tax_entry.irrf = irrf
    end
    tax_entry.operation_at = transaction.operation_at
    tax_entry.settlement_at = transaction.settlement_at
    tax.save!
  end

  def self.tax_free?(stock_sales)
    stock_sales < 20_000
  end

  def self.tax_aliquot(transaction)
    transaction.daytrade? ? 0.20 : 0.15
  end

  def self.name(transaction)
    transaction.ticker
  end

  def self.identifier(transaction)
    transaction.ticker
  end
end
