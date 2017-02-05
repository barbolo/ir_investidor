class CreateBrokers < ActiveRecord::Migration[5.0]
  def change
    create_table :brokers do |t|
      t.string :name
      t.string :cnpj, limit: 14
      t.text :search_terms

      t.timestamps
    end

    add_index :brokers, :name
    add_index :brokers, :cnpj, unique: true
  end
end
