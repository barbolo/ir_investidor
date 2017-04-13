class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable, :rememberable,
         :trackable, :validatable
  (devise :recoverable, :confirmable, :lockable) if Rails.env.production?

  # Associations
  has_many :books_tree, -> { tree }, class_name: 'Book'
  has_many :books, dependent: :destroy, inverse_of: :user
  accepts_nested_attributes_for :books, allow_destroy: true,
    reject_if: lambda { |attributes| attributes['name'].blank? }
  has_many :user_brokers, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :holdings, dependent: :destroy
  has_many :taxes, dependent: :destroy

  # Callbacks
  after_create { Book.initialize_books(self) }

  def start_calculations_signal
    Rails.cache.write("user/calculating/#{id}", true)
  end

  def stop_calculations_signal
    Rails.cache.delete("user/calculating/#{id}")
  end

  def recalculate!(start_date = nil)
    if !calculating?
      start_calculations_signal
      RecalculateTransactionsWorker.perform_in(1.minute, id, start_date)
    end
  end

  def calculating?
    Rails.cache.read("user/calculating/#{id}")
  end

  def tax_for(date)
    period = date.beginning_of_month
    @tax_for ||= {}
    @tax_for[date] ||= taxes.find_or_create_by!(period: period)
  end

  def taxes_by_year_and_month(from = Date.today - 6.years)
    return @taxes_by_year_and_month if @taxes_by_year_and_month
    @taxes_by_year_and_month = {}
    taxes.where('period >= ?', from).each do |tax|
      @taxes_by_year_and_month[tax.period.year] ||= {}
      @taxes_by_year_and_month[tax.period.year][tax.period.month] ||= tax
    end
    @taxes_by_year_and_month
  end
end
