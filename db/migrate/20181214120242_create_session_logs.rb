class CreateSessionLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :session_logs do |t|
      t.belongs_to :session, foreign_key: true
      t.text :message

      t.timestamps
    end
  end
end
