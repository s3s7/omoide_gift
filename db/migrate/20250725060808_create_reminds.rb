class CreateReminds < ActiveRecord::Migration[7.2]
  def change
    create_table :reminds do |t|
      t.date :notification_at
      t.datetime :notification_sent_at
      t.boolean :is_sent
      t.references :user, null: false, foreign_key: true
      t.references :gift_person, null: false, foreign_key: true

      t.timestamps
    end
  end
end
