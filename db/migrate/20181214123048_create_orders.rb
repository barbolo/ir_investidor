class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.belongs_to :session, foreign_key: true, index: false
      t.integer :row
      t.string :asset_class
      t.string :order_type
      t.boolean :daytrade
      t.string :name
      t.integer :quantity
      t.decimal :price, precision: 10, scale: 2
      t.decimal :costs, precision: 10, scale: 2
      t.decimal :irrf, precision: 10, scale: 2
      t.date :ordered_at
      t.date :settlement_at
      t.string :new_name
      t.decimal :old_quantity, precision: 10, scale: 2
      t.decimal :new_quantity, precision: 10, scale: 2

      t.timestamps

      t.index [:session_id, :ordered_at]
    end
  end
end
