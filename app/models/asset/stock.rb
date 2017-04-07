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

  def self.tax_free?
    # vendas < R$ 20.000 ?
  end

  def self.tax_aliquot
    # 15% ou 20%
  end

  def self.name(transaction)
    transaction.ticker
  end

  def self.identifier(transaction)
    transaction.ticker
  end
end
