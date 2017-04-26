class Transaction < ApplicationRecord
  serialize :costs_breakdown, JSON
  store :extra, accessors: [:old_name, :new_name], coder: YAML

  ASSET = {
  # 'code_key'    => 'db_key' (max length: 5)
    'stock'       => 'stock',
    'option'      => 'opt',
  }
  ASSET_REVERSED = Hash[ ASSET.map { |k,v| [v,k] } ]

  ASSET_CLASS = {
    'stock'       => Asset::Stock,
    'option'      => Asset::Option,
  }

  OPERATION = {
  # 'code_key'    => 'db_key' (max length: 5)
    'buy'         => 'buy',
    'sell'        => 'sell',
    'change_name' => 'cname',
  }
  OPERATION_REVERSED = Hash[ OPERATION.map { |k,v| [v,k] } ]

  # Associations
  belongs_to :user
  belongs_to :user_broker
  belongs_to :book, optional: true

  # Validations
  validates :user, presence: true
  validates :user_broker, presence: true
  validates :asset, presence: true, inclusion: { in: ASSET.values }
  validates :operation, presence: true, inclusion: { in: OPERATION.values }
  validate :user_is_the_same
  with_options if: :money_operation? do |tr|
    tr.validates :book, presence: true
    tr.validates :quantity, numericality: { greater_than: 0,
                                            only_integer: true }
    tr.validates :price, numericality: { greater_than_or_equal_to: 0 }
  end
  with_options if: :has_ticker? do |tr|
    tr.validates :ticker, presence: true
  end
  with_options if: 'operation == Transaction::ASSET["change_name"]' do |tr|
    tr.validates :old_name, presence: true
    tr.validates :new_name, presence: true
  end

  # Callbacks
  after_initialize :default_values
  before_validation :default_values
  after_create { process if !user.calculating? }
  after_update { user.recalculate! }
  after_destroy { user.recalculate! }

  def operation_defined?
    asset.present? && operation.present?
  end

  def asset_class
    code = Transaction::ASSET_REVERSED[asset]
    ac = ASSET_CLASS[code]
    fail("Invalid Asset Class for asset #{asset.inspect}") if ac.nil?
    ac
  end

  def asset_class_name
    code = Transaction::ASSET_REVERSED[asset]
    I18n.t code, scope: 'constants.asset'
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

  def has_ticker?
    Transaction::ASSET.slice('stock', 'option').values.include?(asset) &&
      money_operation?
  end

  def money_operation?
    Transaction::OPERATION.slice('buy', 'sell').values.include? operation
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
    elsif operation == Transaction::OPERATION['change_name']
      process_change_name
    else
      asset_class.process(self)
    end
  end

  private
    def default_values
      self.operation_at ||= Date.today
      if quantity && price
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

    def process_change_name
      self.ticker = old_name
      old_identifier = asset_identifier
      self.ticker = new_name
      new_identifier = asset_identifier
      user.holdings.where(asset: asset, asset_identifier: old_identifier)
                   .update_all(asset_identifier: new_identifier,
                               asset_name: new_name )
    end
end
