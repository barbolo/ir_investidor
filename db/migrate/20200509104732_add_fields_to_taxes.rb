class AddFieldsToTaxes < ActiveRecord::Migration[5.2]
  def change
    add_column :taxes, :common_irrf_before, :decimal, precision: 10, scale: 2, unsigned: true, after: :common_irrf
    add_column :taxes, :common_irrf_after, :decimal, precision: 10, scale: 2, unsigned: true, after: :common_irrf_before

    add_column :taxes, :daytrade_irrf_before, :decimal, precision: 10, scale: 2, unsigned: true, after: :daytrade_irrf
    add_column :taxes, :daytrade_irrf_after, :decimal, precision: 10, scale: 2, unsigned: true, after: :daytrade_irrf_before

    add_column :taxes, :fii_irrf_before, :decimal, precision: 10, scale: 2, unsigned: true, after: :fii_irrf
    add_column :taxes, :fii_irrf_after, :decimal, precision: 10, scale: 2, unsigned: true, after: :fii_irrf_before

    add_column :taxes, :common_daytrade_darf, :decimal, precision: 10, scale: 2, unsigned: true, after: :darf
    add_column :taxes, :fii_darf, :decimal, precision: 10, scale: 2, unsigned: true, after: :common_daytrade_darf

    remove_column :taxes, :irrf_before
    remove_column :taxes, :irrf_after
    remove_column :taxes, :tax_due
    remove_column :taxes, :irrf
  end
end
