# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require 'csv'

[
  "#{Rails.root}/db/seeds/empresas_b3.csv",
  "#{Rails.root}/db/seeds/fiis_b3.csv"
].each do |csv_path|
  CSV.foreach(csv_path) do |row|
    ticker, cnpj, razao_social, trading_name = row
    next if Ticker.where(ticker: ticker).exists?
    fake_fulltext_index = []
    fake_fulltext_index << ticker
    fake_fulltext_index << cnpj
    fake_fulltext_index << cnpj.to_s.gsub(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/) { "#{$1}.#{$2}.#{$3}/#{$4}-#{$5}" }
    fake_fulltext_index << cnpj.to_s.gsub(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/) { "#{$1}#{$2}#{$3}/#{$4}-#{$5}" }
    fake_fulltext_index << razao_social
    fake_fulltext_index << trading_name
    fake_fulltext_index = fake_fulltext_index.join(' ').upcase
    Ticker.create!(
      ticker:              ticker,
      cnpj:                cnpj,
      razao_social:        razao_social,
      trading_name:        trading_name,
      fake_fulltext_index: fake_fulltext_index,
    )
    puts "Created ticker: #{ticker}"
  end
end
