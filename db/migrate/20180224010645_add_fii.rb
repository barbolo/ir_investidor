class AddFii < ActiveRecord::Migration[5.0]
  def change
    add_column :taxes, :net_earnings_fii, :decimal, precision: 10, scale: 2, default: "0.0", after: :net_earnings_day_trade
    add_column :taxes, :losses_accumulated_fii, :decimal, precision: 10, scale: 2, default: "0.0", after: :losses_accumulated_day_trade
  end
end
