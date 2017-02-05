class CreateUserBrokers < ActiveRecord::Migration[5.0]
  def change
    create_table :user_brokers do |t|
      t.belongs_to :user, foreign_key: true
      t.belongs_to :broker, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
