class CreateHoldings < ActiveRecord::Migration[5.0]
  def change
    create_table :holdings do |t|
      t.belongs_to :user, foreign_key: true
      t.belongs_to :user_broker, foreign_key: true
      t.belongs_to :book, foreign_key: true
      t.string :asset
      t.string :asset_name
      t.string :asset_identifier
      t.integer :quantity
      t.decimal :initial_price, precision: 10, scale: 6
      t.decimal :current_price, precision: 10, scale: 6
      t.date :last_operation_at

      t.timestamps

      t.index [:user_id, :asset_identifier]
    end
  end
end
