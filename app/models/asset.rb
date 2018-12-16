class Asset < ApplicationRecord
  belongs_to :session

  validates :asset_class, presence: true, inclusion: { in: Order::ASSET_CLASS.values }
  validates :name, presence: true
  validates :quantity, presence: true, numericality: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :current_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :value, presence: true, numericality: true
  validates :current_value, presence: true, numericality: true
  validates :profit, presence: true, numericality: true
  validates :last_order_at, presence: true, inclusion: { in: (Date.today - 20.years)..Date.today.end_of_month }
end
