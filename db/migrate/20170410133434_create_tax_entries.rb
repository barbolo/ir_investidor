class CreateTaxEntries < ActiveRecord::Migration[5.0]
  def change
    create_table :tax_entries do |t|
      t.belongs_to :tax, foreign_key: true
      t.string :asset
      t.string :asset_name
      t.boolean :daytrade
      t.decimal :net_earning, precision: 10, scale: 2, default: 0
      t.decimal :aliquot, precision: 3, scale: 2, default: 0
      t.decimal :tax_value, precision: 8, scale: 2, default: 0
      t.decimal :irrf, precision: 8, scale: 2, default: 0
      t.date :operation_at
      t.date :settlement_at

      t.timestamps

      t.index [:tax_id, :operation_at]
    end
  end
end
