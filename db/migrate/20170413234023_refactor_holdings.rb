class RefactorHoldings < ActiveRecord::Migration[5.0]
  def change
    remove_foreign_key :holdings, :books
    remove_foreign_key :holdings, :user_brokers
    remove_index :holdings, name: 'index_holdings_on_user_id_and_asset_identifier'
    remove_column :holdings, :book_id
    remove_column :holdings, :user_broker_id

    add_column :holdings, :extra, :text, after: :asset_identifier
    add_index :holdings, [:user_id, :asset, :asset_identifier], unique: true
  end
end
