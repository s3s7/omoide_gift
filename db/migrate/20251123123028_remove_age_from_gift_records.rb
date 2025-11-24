class RemoveAgeFromGiftRecords < ActiveRecord::Migration[7.2]
  def change
    remove_reference :gift_records, :age, foreign_key: true, index: true
  end
end
