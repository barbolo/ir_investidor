class Order < ApplicationRecord
  belongs_to :session

  TYPE = {
    'compra'      => 'COMPRA',
    'venda'       => 'VENDA',
    'conversao'   => 'CONVERSAO',
    'compensacao' => 'COMPENSACAO',
    'isencao'     => 'ISENCAO',
    'semisencao'  => 'SEMISENCAO',
  }

  scope :order_by_type, -> { order(Arel.sql('CASE order_type
    WHEN "COMPENSACAO" THEN 0
    WHEN "CONVERSAO"   THEN 1
    WHEN "ISENCAO"     THEN 2
    WHEN "SEMISENCAO"  THEN 3
    WHEN "COMPRA"      THEN 4
    WHEN "VENDA"       THEN 5
    ELSE                    6
    END')) }

  validates :order_type, presence: true, inclusion: { in: Order::TYPE.values }
  validates :ordered_at, presence: true, inclusion: { in: (Date.today - 20.years)..Date.today.end_of_month }

  with_options unless: :compensacao? do |order|
    order.validates :asset_class, presence: true, inclusion: { in: Asset::TYPE.values }
    order.validates :name, presence: true
  end

  with_options if: :compra_venda? do |order|
    order.validates :daytrade, exclusion: { in: [nil] }
    order.validates :quantity, presence: true, numericality: { greater_than: 0 }
    order.validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
    order.validates :costs, presence: true, numericality: { greater_than_or_equal_to: 0 }
    order.validates :irrf, presence: true, numericality: { greater_than_or_equal_to: 0 }
    order.validates :settlement_at, presence: true, inclusion: { in: (Date.today - 20.years)..(Date.today.end_of_month + 10.days) }
  end

  with_options if: :conversao? do |order|
    order.validates :new_name, presence: true
    order.validates :old_quantity, presence: true, numericality: { greater_than: 0 }
    order.validates :new_quantity, presence: true, numericality: { greater_than: 0 }
  end

  with_options if: :compensacao? do |order|
    order.validates :accumulated_common, presence: true, numericality: { greater_than_or_equal_to: 0 }
    order.validates :accumulated_daytrade, presence: true, numericality: { greater_than_or_equal_to: 0 }
    order.validates :accumulated_fii, presence: true, numericality: { greater_than_or_equal_to: 0 }
    order.validates :accumulated_irrf, presence: true, numericality: { greater_than_or_equal_to: 0 }
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

    def compensacao?
      Order::TYPE['compensacao'] == order_type
    end
end
