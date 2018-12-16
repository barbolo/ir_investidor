class CreateSessions < ActiveRecord::Migration[5.2]
  def change
    create_table :sessions do |t|
      t.string :secret, limit: 64
      t.boolean :sheet_ready
      t.boolean :orders_ready
      t.boolean :calcs_ready
      t.integer :orders_count, unsigned: true
      t.decimal :assets_value, precision: 10, scale: 2
      t.string :error

      t.timestamp :expire_at

      t.timestamps

      t.index [:secret], unique: true
    end
  end
end
