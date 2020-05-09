class Ticker < ApplicationRecord
  def self.search(terms)
    query = Ticker.order(:ticker)
    terms.split(/\s+/).each do |term|
      query = query.where('fake_fulltext_index like ?', "%#{term.upcase}%")
    end
    query
  end

  def cnpj_formatado
    cnpj.to_s.gsub(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/) { "#{$1}.#{$2}.#{$3}/#{$4}-#{$5}" }
  end
end
