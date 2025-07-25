class CreateFavorites < ActiveRecord::Migration[7.2]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :gift_record, null: false, foreign_key: true

      t.timestamps
    end
  end
end
