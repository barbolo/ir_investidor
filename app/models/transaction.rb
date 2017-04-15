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
  after_create :process
  after_update { user.recalculate! }
  after_destroy { user.recalculate! }

  def operation_defined?
    asset.present? && operation.present?
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

  def asset_identifier
    asset_class.identifier(self)
  end

  def price_considering_costs
    case operation
    when Transaction::OPERATION['buy']
      (quantity * price + costs) / quantity
    when Transaction::OPERATION['sell']
      (quantity * price - costs) / quantity
    else
      price
    end
  end

  def quantity_with_sign
    (operation == Transaction::OPERATION['sell']) ? (- quantity) : quantity
  end

  # An inverse holding is an asset in the porfolio that will be decreased with
  # this transaction. For example, if the portfolio has 100 shares of XYZ and
  # this transaction sells 100 shares of XYZ, then there's an inverse holding of
  # 100 shares.
  def inverse_holding
    return @inverse_holding if @calculated_inverse_holding
    @calculated_inverse_holding = true
    holding = Holding.for(self)
    if holding.present? &&
       ((operation == Transaction::OPERATION['sell'] && holding.quantity > 0) ||
        (operation == Transaction::OPERATION['buy'] && holding.quantity < 0))
      @inverse_holding = holding
    else
      @inverse_holding = nil
    end
  end

  # TODO: in order to process day trade vs. normal trade, we need to create
  # holdings for day trade operations that are converted to normal holdings
  # when they are not considered day trade anymore.
  def daytrade?
    inverse_holding.try(:last_operation_at) == operation_at
  end

  def net_earnings
    if inverse_holding
      qtd = [quantity.abs, inverse_holding.quantity.abs].min
      qtd * (price_considering_costs - inverse_holding.initial_price)
    else
      0
    end
  end

  def process
    if Holding.affect_current_holdings?(self)
      user.recalculate!(operation_at.beginning_of_month)
    else
      asset_class.process(self)
    end
  end

  private
    def default_values
      self.operation_at ||= Date.today
      if quantity && price && quantity > 0 && price > 0
        self.value = quantity * price
      end
      if asset && value
        self.costs_breakdown = asset_class.costs(self) if costs_breakdown.blank?
        self.costs = costs_breakdown.values.map { |v| BigDecimal.new(v)}.sum.floor(2)
        self.irrf ||= asset_class.irrf(self) if irrf.blank? || irrf == 0
      end
      self.ticker = ticker.upcase if ticker.is_a?(String)
    end

    def user_is_the_same
      errors.add(:user_broker, :invalid) if user_broker.user_id != user_id
      errors.add(:book, :invalid) if book && (book.user_id != user_id)
    end
end
