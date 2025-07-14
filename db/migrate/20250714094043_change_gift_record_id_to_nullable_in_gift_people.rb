class ChangeGiftRecordIdToNullableInGiftPeople < ActiveRecord::Migration[7.2]
  def change
    change_column_null :gift_people, :gift_record_id, true
  end
end
