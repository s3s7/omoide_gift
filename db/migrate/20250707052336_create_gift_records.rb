class CreateGiftRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :gift_records do |t|
      t.string :memo
      t.string :gift_image
      t.string :item_name
      t.integer :amount
      t.boolean :is_public
      t.date :gift_at
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :gift_person, null: false, foreign_key: true

      t.timestamps
    end
  end
end
