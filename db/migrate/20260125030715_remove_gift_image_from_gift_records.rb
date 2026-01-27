class RemoveGiftImageFromGiftRecords < ActiveRecord::Migration[7.2]
  def change
    remove_column :gift_records, :gift_image, :string
  end
end
