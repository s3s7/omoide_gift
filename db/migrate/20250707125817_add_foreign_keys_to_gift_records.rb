class AddForeignKeysToGiftRecords < ActiveRecord::Migration[7.2]
  def change
    add_reference :gift_records, :user, foreign_key: true
    add_reference :gift_records, :event, foreign_key: true
    add_reference :gift_records, :gift_person, foreign_key: true
  end
end
