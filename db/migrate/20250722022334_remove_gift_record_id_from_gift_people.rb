class RemoveGiftRecordIdFromGiftPeople < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :gift_people, :gift_records
    remove_reference :gift_people, :gift_record, index: true
  end
end
