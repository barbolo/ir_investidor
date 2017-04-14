require 'csv'

namespace :holdings do
  desc '[Temporary Task] Update prices of all holdings'
  task :update => :environment do
    stocks = []
    holdings = Holding.group(:asset, :asset_name).pluck(:asset, :asset_name)
    holdings.each do |asset, asset_name|
      if asset == Transaction::ASSET['stock']
        stocks << asset_name.upcase.strip + '.SA'
      end
    end

    args = {
      's' => stocks.join(' '),
      'f' => 'sl1'
    }
    url = "?s=HYPE3.SA+BVMF3.SA&f=sl1"
    agent = Mechanize.new
    agent.get('http://finance.yahoo.com/d/quotes.csv', args)
    CSV.parse(agent.page.body).each do |row|
      symbol, price = row
      symbol = symbol.gsub(/\.SA\Z/, '')
      Holding.where(asset: Transaction::ASSET['stock'])
             .where(asset_name: symbol)
             .update_all(current_price: BigDecimal.new(price))
    end
    agent.shutdown
  end
end
