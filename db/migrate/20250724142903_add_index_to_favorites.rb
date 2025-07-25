class AddIndexToFavorites < ActiveRecord::Migration[7.2]
  def change
     add_index :favorites, [ :user_id, :gift_record_id ], unique: true
  end
end
