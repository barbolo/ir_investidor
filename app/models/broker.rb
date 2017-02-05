class Broker < ApplicationRecord
  # A user needs to create broker(s) account(s) in order to register investment
  # operations.
  #
  # We are seeding the brokers from the link below:
  # http://www.bmfbovespa.com.br/pt_br/servicos/participantes/busca-de-corretoras/
  #
  # If your broker is not listed in the link above, open an issue or send a pull
  # request.

  # Associations
  has_many :user_brokers

  # Scopes
  default_scope { order(:name) }

  # Validations
  validates :name, presence: true
  validates :cnpj, presence: true, uniqueness: true
  validates :search_terms, presence: true

  # Callbacks
  before_validation :set_search_terms

  def formatted_cnpj
    cnpj.to_s.gsub(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/) { "#{$1}.#{$2}.#{$3}/#{$4}-#{$5}" }
  end

  private
    def set_search_terms
      terms = []
      terms << name
      terms << name.to_s.gsub(/[^a-z0-9 ]/i, '')
      terms << cnpj
      terms << formatted_cnpj
      self.search_terms = terms.uniq.join(' ')
    end
end
