class CreateTaxEntries < ActiveRecord::Migration[5.2]
  def change
    create_table :tax_entries do |t|
      t.belongs_to :tax, foreign_key: true, index: false

      t.string :asset_class
      t.string :name
      t.boolean :daytrade
      t.decimal :tax_aliquot, precision: 10, scale: 6, unsigned: true
      t.decimal :irrf_aliquot, precision: 10, scale: 6, unsigned: true
      t.decimal :earnings, precision: 10, scale: 2
      t.decimal :tax_due, precision: 10, scale: 2, unsigned: true
      t.decimal :irrf, precision: 10, scale: 2, unsigned: true
      t.datetime :disposed_at

      t.timestamps

      t.index [:tax_id, :asset_class, :disposed_at]
    end
  end
end
