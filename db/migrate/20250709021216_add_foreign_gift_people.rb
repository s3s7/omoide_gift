class AddForeignGiftPeople < ActiveRecord::Migration[7.2]
  def change
        add_reference :gift_records, :gift_people, foreign_key: true
  end
end
