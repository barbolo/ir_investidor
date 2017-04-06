class Transaction < ApplicationRecord
  serialize :costs_breakdown, JSON

  ASSET = {
  # 'code_key'    => 'db_key' (max length: 5)
    'stock'       => 'stock',
  }
  ASSET_REVERSED = Hash[ ASSET.map { |k,v| [v,k] } ]

  ASSET_CLASS = {
    'stock'       => Asset::Stock,
  }

  OPERATION = {
  # 'code_key'    => 'db_key' (max length: 5)
    'buy'         => 'buy',
    'sell'        => 'sell',
  }
  OPERATION_REVERSED = Hash[ OPERATION.map { |k,v| [v,k] } ]

  # Associations
  belongs_to :user
  belongs_to :user_broker
  belongs_to :book

  # Scopes
  default_scope { order('operation_at DESC') }

  # Validations
  validates :user, presence: true
  validates :user_broker, presence: true
  validates :book, presence: true
  validates :asset, presence: true, inclusion: { in: ASSET.values }
  validates :operation, presence: true, inclusion: { in: OPERATION.values }
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :price, numericality: { greater_than: 0 }
  validate :user_is_the_same
  with_options if: 'asset == Transaction::ASSET["stock"]' do |stock|
    stock.validates :ticker, presence: true
  end

  # Callbacks
  after_initialize :default_values
  before_validation :default_values

  def operation_defined?
    asset.present? && operation.present?
  end

  def daytrade?
    false
  end

  def inverse_holding
    nil
  end

  def net_earnings
    if inverse_holding
      qtd = [quantity, inverse_holding.quantity].min
      qtd * (price - inverse_holding.price)
    else
      0
    end
  end

  def asset_class
    ac = ASSET_CLASS[asset]
    fail("Invalid Asset Class for asset #{asset.inspect}") if ac.nil?
    ac
  end

  def asset_class_name
    I18n.t asset, scope: 'constants.asset'
  end

  def operation_name
    code = Transaction::OPERATION_REVERSED[operation]
    I18n.t code, scope: 'constants.operation'
  end

  def asset_name
    asset_class.name(self)
  end

  private
    def default_values
      self.operation_at ||= Date.today
      self.settlement_at ||= operation_at + 3.days
      if quantity && price && quantity > 0 && price > 0
        self.value = quantity * price
      end
      if asset && value
        self.costs_breakdown = asset_class.costs(self) if costs_breakdown.blank?
        self.costs = costs_breakdown.values.map { |v| BigDecimal.new(v)}.sum.floor(2)
        self.irrf ||= asset_class.irrf(self) if irrf.blank? || irrf == 0
      end
    end

    def user_is_the_same
      errors.add(:user_broker, :invalid) if user_broker.user_id != user_id
      errors.add(:book, :invalid) if book && (book.user_id != user_id)
    end
end
