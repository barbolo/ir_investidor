class CreateTaxes < ActiveRecord::Migration[5.0]
  def change
    create_table :taxes do |t|
      t.belongs_to :user, foreign_key: true
      t.date :period
      t.decimal :net_earnings, precision: 10, scale: 2, default: 0
      t.decimal :net_earnings_day_trade, precision: 10, scale: 2, default: 0
      t.decimal :losses_accumulated, precision: 10, scale: 2, default: 0
      t.decimal :losses_accumulated_day_trade, precision: 10, scale: 2, default: 0
      t.decimal :irrf, precision: 8, scale: 2, default: 0
      t.decimal :irrf_accumulated_to_compensate, precision: 8, scale: 2, default: 0
      t.decimal :stock_sales, precision: 10, scale: 2, default: 0
      t.decimal :darf, precision: 8, scale: 2, default: 0

      t.timestamps

      t.index [:user_id, :period]
    end
  end
end

