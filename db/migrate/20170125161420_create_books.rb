class CreateBooks < ActiveRecord::Migration[5.0]
  def change
    create_table :books do |t|
      t.string :name
      t.belongs_to :user, foreign_key: true, index: true
      t.references :parent, index: true
      t.integer :position

      t.timestamps
    end
  end
end
