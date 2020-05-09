class CreateTickers < ActiveRecord::Migration[5.2]
  def change
    create_table :tickers do |t|
      t.string :ticker, limit: 20
      t.string :cnpj, limit: 15
      t.text :razao_social, limit: 255
      t.text :trading_name, limit: 255
      t.text :fake_fulltext_index

      t.timestamps

      t.index :ticker, unique: true
    end
  end
end
