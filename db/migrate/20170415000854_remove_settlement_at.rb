class RemoveSettlementAt < ActiveRecord::Migration[5.0]
  def change
    remove_column :transactions, :settlement_at
    remove_column :tax_entries, :settlement_at
  end
end
