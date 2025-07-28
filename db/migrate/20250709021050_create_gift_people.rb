class CreateGiftPeople < ActiveRecord::Migration[7.2]
  def change
    create_table :gift_people do |t|
      t.string :name
      t.string :likes
      t.string :dislikes
      t.date :birthday
      t.string :memo
      t.string :gift_peoples_image
      t.references :user, null: false, foreign_key: true
      t.references :gift_record, null: false, foreign_key: true
      t.references :relationship, null: false, foreign_key: true

      t.timestamps
    end
  end
end
