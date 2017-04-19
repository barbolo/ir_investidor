class AddStoreFieldToTransaction < ActiveRecord::Migration[5.0]
  def change
    add_column :transactions, :extra, :text, after: :expire_at
  end
end
