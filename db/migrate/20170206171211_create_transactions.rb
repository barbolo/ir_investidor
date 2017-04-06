class CreateTransactions < ActiveRecord::Migration[5.0]
  def change
    create_table :transactions do |t|
      t.belongs_to :user, foreign_key: true
      t.belongs_to :user_broker, foreign_key: true
      t.belongs_to :book, foreign_key: true
      t.string :asset, limit: 5
      t.string :operation, limit: 5
      t.string :name, limit: 100
      t.string :ticker
      t.decimal :fixed_rate, precision: 5, scale: 2
      t.string :index_name
      t.decimal :index_rate, precision: 5, scale: 4
      t.integer :quantity
      t.decimal :price, precision: 7, scale: 2
      t.decimal :value, precision: 10, scale: 2
      t.text :costs_breakdown
      t.decimal :costs, precision: 8, scale: 2
      t.decimal :irrf, precision: 8, scale: 2
      t.date :operation_at
      t.date :settlement_at
      t.date :expire_at

      t.timestamps
    end

    add_index :transactions, [:operation_at, :user_id, :book_id]
    add_index :transactions, [:user_id, :expire_at]
  end
end
