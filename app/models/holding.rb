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

  def self.affect_current_holdings?(transaction)
    return true if !transaction.user.calculating? &&
                   transaction.operation_at < Date.today.beginning_of_month
    cond = Holding.where(user_id: transaction.user_id)
    cond = cond.where('last_operation_at > ?', transaction.operation_at)
    cond.exists?
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
