class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.belongs_to :session, foreign_key: true, index: false
      t.integer :row, unsigned: true
      t.string :asset_class
      t.string :order_type
      t.boolean :daytrade
      t.string :name
      t.integer :quantity, unsigned: true
      t.decimal :price, precision: 10, scale: 2, unsigned: true
      t.decimal :costs, precision: 10, scale: 2, unsigned: true
      t.decimal :irrf, precision: 10, scale: 2, unsigned: true
      t.date :ordered_at
      t.date :settlement_at
      t.string :new_name
      t.decimal :old_quantity, precision: 10, scale: 2, unsigned: true
      t.decimal :new_quantity, precision: 10, scale: 2, unsigned: true
      t.decimal :accumulated_common, precision: 10, scale: 2, unsigned: true
      t.decimal :accumulated_daytrade, precision: 10, scale: 2, unsigned: true
      t.decimal :accumulated_fii, precision: 10, scale: 2, unsigned: true
      t.decimal :accumulated_irrf, precision: 10, scale: 2, unsigned: true

      t.timestamps

      t.index [:session_id, :ordered_at]
    end
  end
end
