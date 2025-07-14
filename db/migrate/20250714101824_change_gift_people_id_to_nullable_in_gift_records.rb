class ChangeGiftPeopleIdToNullableInGiftRecords < ActiveRecord::Migration[7.2]
  def change
    change_column_null :gift_records, :gift_people_id, false
  end
end
