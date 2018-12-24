class Tax < ApplicationRecord
  belongs_to :session
  has_many :tax_entries, dependent: :destroy
end
