class Book < ApplicationRecord
  # A book is like a category of investment. It helps you visualize the
  # allocation strategy of your current portfolio. Examples of books: Stocks,
  # Options, Gold, Long/Short, Buy and Hold, Foreign Exchange. A book may belong
  # to another book, so you can build a collection of books like the following:
  #
  # > Renda Fixa
  #     > CDI
  #     > IPCA
  #     > Préfixado
  # > Ações
  # > Ouro
  #
  # In this tree example, "CDI", "IPCA" and "Préfixado" belong to "Renda Fixa".
  #
  # The application will not work with a tree with level >= 3 and it will not
  # validate that a Book is being created in such levels. The GUI will not allow
  # such behaviour.
  #
  # When a new user is created, a collection of default books will be added to
  # the user's account. It can be changed later by the user with whatever she
  # thinks is best for organizing her portfolio.

  COLORS = %w(#4abdac #a239ca #f7b733 #fc4a1a #8c52ff #e16eff #ff55a2 #9a6447
              #739a55 #461d16 #740000 #4b2c51 #0f1569 #b25454 #4e7b85 #4885ed
              #f24333 #b3d94e #d13446 #008fff #b72a62 #525300 #dd745a #8fa0bf)

  # Associations
  belongs_to :user, inverse_of: :books
  has_many :children, class_name: 'Book', foreign_key: 'parent_id',
           dependent: :destroy
  belongs_to :parent, class_name: 'Book', required: false
  has_many :transactions

  # Scopes
  default_scope { order(:position) }
  scope :tree, -> { where(parent_id: nil).includes(:children) }

  # Validations
  validates :user, presence: true
  validates :name, presence: true
  validate :parent_user_is_the_same_user

  # Callbacks
  after_initialize :default_values

  def self.initialize_books(user)
    ActiveRecord::Base.transaction do
      pos = 0
      rf = Book.create!(user_id: user.id, name: 'Renda Fixa', position: pos)
      Book.create!(user_id: user.id, parent: rf, name: 'CDI', position: pos += 1)
      Book.create!(user_id: user.id, parent: rf, name: 'IPCA', position: pos += 1)
      Book.create!(user_id: user.id, parent: rf, name: 'Préfixado', position: pos += 1)
      Book.create!(user_id: user.id, name: 'Dólar', position: pos += 1)
      Book.create!(user_id: user.id, name: 'Ouro', position: pos += 1)
      Book.create!(user_id: user.id, name: 'Ações', position: pos += 1)
      Book.create!(user_id: user.id, name: 'Opções', position: pos += 1)
      Book.create!(user_id: user.id, name: 'Fundos Imobiliários', position: pos += 1)
      Book.create!(user_id: user.id, name: 'Venda coberta', position: pos += 1)
      Book.create!(user_id: user.id, name: 'Long/short', position: pos += 1)
    end
  end

  def color
    Book::COLORS[position.to_i % Book::COLORS.size]
  end

  private
    def default_values
      self.position ||= -1
    end

    def parent_user_is_the_same_user
      if parent_id.present? && parent.user != user
        errors.add(:parent, :invalid)
      end
    end
end
