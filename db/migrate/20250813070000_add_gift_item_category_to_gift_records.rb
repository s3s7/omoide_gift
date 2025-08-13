class AddGiftItemCategoryToGiftRecords < ActiveRecord::Migration[7.2]
  def change
    add_reference :gift_records, :gift_item_category, foreign_key: true
  end
end
