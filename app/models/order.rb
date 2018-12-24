class Order < ApplicationRecord
  belongs_to :session

  TYPE = {
    'compra'     => 'COMPRA',
    'venda'      => 'VENDA',
    'conversao'  => 'CONVERSAO',
  }

  scope :order_by_type, -> { order(Arel.sql('CASE order_type
    WHEN "CONVERSAO" THEN 0
    WHEN "COMPRA"    THEN 1
    WHEN "VENDA"     THEN 2
    ELSE                  3
    END')) }

  validates :asset_class, presence: true, inclusion: { in: Asset::TYPE.values }
  validates :order_type, presence: true, inclusion: { in: Order::TYPE.values }
  validates :name, presence: true

  with_options if: :compra_venda? do |order|
    order.validates :daytrade, exclusion: { in: [nil] }
    order.validates :quantity, presence: true, numericality: { greater_than: 0 }
    order.validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
    order.validates :costs, presence: true, numericality: { greater_than_or_equal_to: 0 }
    order.validates :irrf, presence: true, numericality: { greater_than_or_equal_to: 0 }
    order.validates :ordered_at, presence: true, inclusion: { in: (Date.today - 20.years)..Date.today.end_of_month }
    order.validates :settlement_at, presence: true, inclusion: { in: (Date.today - 20.years)..(Date.today.end_of_month + 10.days) }
  end

  with_options if: :conversao? do |order|
    order.validates :new_name, presence: true
    order.validates :old_quantity, presence: true, numericality: { greater_than: 0 }
    order.validates :new_quantity, presence: true, numericality: { greater_than: 0 }
  end

  def price_considering_costs
    case order_type
    when Order::TYPE['compra']
      (quantity * price + costs) / quantity
    when Order::TYPE['venda']
      (quantity * price - costs) / quantity
    else
      price
    end
  end

  private
    def compra_venda?
      Order::TYPE.slice('compra', 'venda').values.include?(order_type)
    end

    def conversao?
      Order::TYPE['conversao'] == order_type
    end
end
