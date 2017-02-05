require 'csv'
module Seeds
end

require_relative 'seeds/brokers'

puts 'Initializing seeds'

# Brokers
puts 'Brokers'
Seeds::Brokers.all.each do |item|
  cnpj, name = item
  broker = Broker.where(cnpj: cnpj).first_or_initialize
  unless broker.persisted?
    broker.name = name
    broker.save!
    puts "new broker # #{broker.cnpj} / #{broker.name}"
  end
end

puts 'Finished seeds'
