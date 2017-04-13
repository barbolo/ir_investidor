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

  def self.process(transaction)
    Asset::Stock.tax_update_stock_sales(transaction)

    holdings = Holding.holdings_for(transaction)
    if holdings.blank?
      # create a new holding
      holding = Holding.new
      holding.user_id           = transaction.user_id
      holding.user_broker_id    = transaction.user_broker_id
      holding.book_id           = transaction.book_id
      holding.asset             = transaction.asset
      holding.asset_identifier  = transaction.asset_identifier
      holding.asset_name        = transaction.asset_name
      holding.quantity          = transaction.quantity_with_sign
      holding.initial_price     = transaction.price_considering_costs
      holding.current_price     = holding.initial_price
      holding.last_operation_at = transaction.operation_at
      holding.save!

    else
      # find quantity and average initial price of current holdings
      qtd   = holdings.sum { |h| h.quantity }
      price = holdings.sum { |h| h.quantity * h.initial_price } / qtd
      transaction_quantity = transaction.quantity_with_sign

      if qtd * transaction_quantity < 0 && qtd.abs < transaction_quantity.abs
        # TODO: create a log inside the system to register this case.
        # This should be processed like two operations: one do destroy the
        # current holding and another to create a new inverse position.
        fail("Invalid transaction: #{transaction.id}")
      end

      # Try to find a holding with the same book of the transaction
      holding = holdings.find { |h| h.book_id == transaction.book_id }

      if qtd * transaction_quantity < 0
        # decrease our assets holding
        holding ||= holdings.first

        # Add tax entry
        Asset::Stock.add_tax_entry(transaction)

        decreased = []
        decrease = transaction.quantity
        while decrease > 0 && holding.present?
          decreased << holding.id
          decrease_step = [holding.quantity.abs, decrease].min

          if holding.quantity > 0
            holding.quantity -= decrease_step
          else
            holding.quantity += decrease_step
          end
          holding.quantity == 0 ? holding.destroy : holding.save!

          holding = holdings.find { |h| !h.id.in?(decreased) }
          decrease -= decrease_step
        end

      else
        price = ((transaction.quantity * transaction.price_considering_costs) +
               (qtd * price)) / (transaction.quantity + qtd)

        # increase our assets holding
        if holding.present?
          holding.quantity += transaction_quantity
          holding.quantity == 0 ? holding.destroy : holding.save!

        else
          # create a holding for a new book
          holding = Holding.new
          holding.user_id           = transaction.user_id
          holding.user_broker_id    = transaction.user_broker_id
          holding.book_id           = transaction.book_id
          holding.asset             = transaction.asset
          holding.asset_identifier  = transaction.asset_identifier
          holding.asset_name        = transaction.asset_name
          holding.quantity          = transaction_quantity
          holding.initial_price     = price
          holding.current_price     = holdings.first.current_price
          holding.save!
        end

        puts 'AKSJKDJAKJSKJAKS'
        Holding.where(id: holdings.map(&:id)).update_all(
          initial_price: price, last_operation_at: transaction.operation_at)
      end
    end
  end

  def self.tax_update_stock_sales(transaction)
    if transaction.operation == Transaction::OPERATION['sell']
      tax = transaction.user.tax_for(transaction.operation_at)
      tax.stock_sales += transaction.value
      tax.save!
    end
  end

  def self.add_tax_entry(transaction)
    net_earnings = transaction.net_earnings
    daytrade = transaction.daytrade?
    irrf = transaction.irrf
    aliquot = Asset::Stock.tax_aliquot(transaction)

    tax = transaction.user.tax_for(transaction.operation_at)
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
end
