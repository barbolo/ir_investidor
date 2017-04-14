class Holding < ApplicationRecord
  store :extra, accessors: [:user_brokers, :books], coder: YAML

  # Associations
  belongs_to :user

  # Callbacks
  after_initialize :default_values
  before_save :fix_values

  def self.for(transaction)
    Holding.where(user_id: transaction.user_id,
                  asset: transaction.asset,
                  asset_identifier: transaction.asset_identifier).first
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

  private
    def default_values
      self.user_brokers ||= {}
      self.books        ||= {}
    end

    def fix_values
      user_brokers.keys.each do |key|
        self.user_brokers.delete(key) if user_brokers[key].to_i == 0
      end
      books.keys.each do |key|
        self.books.delete(key) if books[key].to_i == 0
      end
    end
end
