class CreateAssets < ActiveRecord::Migration[5.2]
  def change
    create_table :assets do |t|
      t.belongs_to :session, foreign_key: true, index: false
      t.string :asset_class
      t.string :name
      t.integer :quantity
      t.decimal :price, precision: 10, scale: 2, unsigned: true
      t.decimal :current_price, precision: 10, scale: 2, unsigned: true
      t.decimal :value, precision: 10, scale: 2
      t.decimal :current_value, precision: 10, scale: 2
      t.decimal :profit, precision: 10, scale: 2
      t.date :last_order_at

      t.timestamps

      t.index [:session_id, :asset_class, :name]
    end
  end
end
