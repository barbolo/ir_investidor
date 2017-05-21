require 'csv'

def update_stocks(stocks)
  puts "Updating #{stocks.size} stocks..."
  args = {
    's' => stocks.map { |s| s + '.SA' }.join(' '),
    'f' => 'sl1'
  }
  agent = Mechanize.new
  agent.get('http://finance.yahoo.com/d/quotes.csv', args)
  CSV.parse(agent.page.body).each do |row|
    symbol, price = row
    symbol = symbol.gsub(/\.SA\Z/, '')
    puts "#{symbol}: #{price}"
    Holding.where(asset: Transaction::ASSET['stock'])
           .where(asset_name: symbol)
           .update_all(current_price: BigDecimal.new(price))
  end
  agent.shutdown

  puts "Stocks updated"
end

def update_options(options)
  puts "Updating #{options.size} options..."

  headers = { 'X-Requested-With' => 'XMLHttpRequest' }

  options.each do |option|

    agent = Mechanize.new

    args = { 'term' => option }
    agent.get 'https://www.itaucorretora.com.br/cotacao/retornarpapeis/', args, nil, headers

    args = {
      'ativo'           => option,
      'stocksToCompare' => '',
      'currentOffers'   => '1',
      'prevStock'       => ''
    }
    agent.get 'https://www.itaucorretora.com.br/finder/resultadobusca', args, nil, headers

    if agent.page.body.match(/N.+o foram encontrados ativos para sua busca/)
      # it's probably an expired option
      price = '0.00'

    else
      price = agent.page.parser.css('#stock-integer .secao.preco strong').text
      price = price.strip.gsub('.', '').gsub(',', '.').gsub(/[^0-9.]/, '')
    end

    agent.shutdown

    puts "#{option}: #{price}"

    Holding.where(asset: Transaction::ASSET['option'])
           .where(asset_name: option)
           .update_all(current_price: BigDecimal.new(price))
  end

  puts "Options updated"
end

namespace :holdings do
  desc '[Temporary Task] Update prices of all holdings'
  task :update => :environment do
    # find all current holdings
    holdings = {}
    all = Holding.group(:asset, :asset_name).pluck(:asset, :asset_name)
    all.each do |asset, asset_name|
      holdings[asset] ||= []
      holdings[asset] << asset_name.upcase.strip
    end

    Transaction::ASSET # preload before using inside threads

    threads = []
    threads << Thread.new { update_stocks(holdings[Transaction::ASSET['stock']]) }
    threads << Thread.new { update_options(holdings[Transaction::ASSET['option']]) }
    threads.each &:join
  end
end
