class RemoveGiftRecordIdFromGiftPeople < ActiveRecord::Migration[7.2]
  def change
    remove_reference :gift_people, :gift_record_id, null: false, foreign_key: true
  end
end
