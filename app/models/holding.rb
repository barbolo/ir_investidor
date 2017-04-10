class Holding < ApplicationRecord
  belongs_to :user
  belongs_to :user_broker
  belongs_to :book

  def self.holdings_for(transaction)
    args = {
      user_id: transaction.user_id,
      user_broker_id: transaction.user_broker_id,
      asset: transaction.asset,
      asset_identifier: transaction.asset_identifier
    }
    Holding.where(args).all
  end

  def self.process(transaction)
    cond = Holding.where(user_id: transaction.user_id)
    cond = cond.where('last_operation_at > ?', transaction.operation_at)
    if cond.exists?
      transaction.user.start_calculations_signal
      RecalculateTransactionsWorker.perform_async(transaction.user_id,
                                                  transaction.operation_at)
      return
    end

    if transaction.operation == Transaction::OPERATION['sell']
      transaction_quantity = - transaction.quantity
    else
      transaction_quantity = transaction.quantity
    end

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
      holding.quantity          = transaction_quantity
      holding.initial_price     = transaction.price_considering_costs
      holding.current_price     = holding.initial_price
      holding.last_operation_at = transaction.operation_at
      holding.save!

    else
      qtd   = holdings.sum { |h| h.quantity }
      price = holdings.sum { |h| h.quantity * h.initial_price } / qtd

      if qtd * transaction_quantity < 0 && qtd.abs < transaction_quantity.abs
        # TODO: create a log inside the system to register this case
        fail("Invalid transaction: #{transaction.id}")
      end

      # Try to find a holding in the same book
      holding = holdings.find { |h| h.book_id == transaction.book_id }

      if qtd * transaction_quantity < 0
        # decrease our assets holding
        holding ||= holdings.first

        # Add tax entry
        transaction.asset_class.add_tax_entry(transaction)

        decreased = []
        decrease = transaction_quantity.abs
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
          holding.quantity          = transaction.quantity
          holding.initial_price     = price
          holding.current_price     = holdings.first.current_price
          holding.save!
        end
      end

      Holding.where(id: holdings.map(&:id)).update_all(
        initial_price: price, last_operation_at: transaction.operation_at)
    end
  end

  def initial_value
    quantity * initial_price
  end

  def current_value
    quantity * current_price
  end

  def net_profit
    current_value - initial_value
  end

  def net_profit_percentage
    100*(current_value/initial_value - 1)
  end
end
