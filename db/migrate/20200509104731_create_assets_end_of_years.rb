class CreateAssetsEndOfYears < ActiveRecord::Migration[5.2]
  def change
    create_table :assets_end_of_years do |t|
      t.belongs_to :session, foreign_key: true, index: false
      t.integer :year, limit: 2
      t.json :assets

      t.timestamps

      t.index [:session_id, :year]
    end
  end
end
