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

  # Callbacks
  after_create { Book.initialize_books(self) }

  def start_calculations_signal
    Rails.cache.write("user/calculating/#{id}", true)
  end

  def stop_calculations_signal
    Rails.cache.delete("user/calculating/#{id}")
  end

  def calculating?
    Rails.cache.read("user/calculating/#{id}")
  end
end
