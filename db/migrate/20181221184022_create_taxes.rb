class CreateTaxes < ActiveRecord::Migration[5.2]
  def change
    create_table :taxes do |t|
      t.belongs_to :session, foreign_key: true, index: false

      t.date :period
      t.decimal :darf, precision: 10, scale: 2, unsigned: true
      t.decimal :tax_due, precision: 10, scale: 2, unsigned: true
      t.decimal :irrf, precision: 10, scale: 2, unsigned: true
      t.decimal :irrf_before, precision: 10, scale: 2, unsigned: true
      t.decimal :irrf_after, precision: 10, scale: 2, unsigned: true
      t.decimal :stocks_sales, precision: 10, scale: 2, unsigned: true
      t.decimal :stocks_taxfree_profits, precision: 10, scale: 2, unsigned: true
      t.decimal :common_tax_aliquot, precision: 10, scale: 6, unsigned: true
      t.decimal :common_irrf_aliquot, precision: 10, scale: 6, unsigned: true
      t.decimal :common_stocks_earnings, precision: 10, scale: 2
      t.decimal :common_options_earnings, precision: 10, scale: 2
      t.decimal :common_subscriptions_earnings, precision: 10, scale: 2
      t.decimal :common_earnings, precision: 10, scale: 2
      t.decimal :common_sales, precision: 10, scale: 2, unsigned: true
      t.decimal :common_losses_before, precision: 10, scale: 2, unsigned: true
      t.decimal :common_taxable_value, precision: 10, scale: 2, unsigned: true
      t.decimal :common_losses_after, precision: 10, scale: 2, unsigned: true
      t.decimal :common_tax_due, precision: 10, scale: 2, unsigned: true
      t.decimal :common_irrf, precision: 10, scale: 2, unsigned: true
      t.decimal :daytrade_tax_aliquot, precision: 10, scale: 6, unsigned: true
      t.decimal :daytrade_irrf_aliquot, precision: 10, scale: 6, unsigned: true
      t.decimal :daytrade_stocks_earnings, precision: 10, scale: 2
      t.decimal :daytrade_options_earnings, precision: 10, scale: 2
      t.decimal :daytrade_earnings, precision: 10, scale: 2
      t.decimal :daytrade_sales, precision: 10, scale: 2, unsigned: true
      t.decimal :daytrade_losses_before, precision: 10, scale: 2, unsigned: true
      t.decimal :daytrade_taxable_value, precision: 10, scale: 2, unsigned: true
      t.decimal :daytrade_losses_after, precision: 10, scale: 2, unsigned: true
      t.decimal :daytrade_tax_due, precision: 10, scale: 2, unsigned: true
      t.decimal :daytrade_irrf, precision: 10, scale: 2, unsigned: true
      t.decimal :fii_tax_aliquot, precision: 10, scale: 6, unsigned: true
      t.decimal :fii_earnings, precision: 10, scale: 2
      t.decimal :fii_sales, precision: 10, scale: 2, unsigned: true
      t.decimal :fii_losses_before, precision: 10, scale: 2, unsigned: true
      t.decimal :fii_taxable_value, precision: 10, scale: 2, unsigned: true
      t.decimal :fii_losses_after, precision: 10, scale: 2, unsigned: true
      t.decimal :fii_tax_due, precision: 10, scale: 2, unsigned: true
      t.decimal :fii_irrf, precision: 10, scale: 2, unsigned: true

      t.timestamps

      t.index [:session_id, :period]
    end
  end
end
