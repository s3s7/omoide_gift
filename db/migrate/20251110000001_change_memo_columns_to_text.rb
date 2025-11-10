class ChangeMemoColumnsToText < ActiveRecord::Migration[7.2]
  def up
    change_column :gift_records, :memo, :text
    change_column :gift_people, :memo, :text
  end

  def down
    # Revert to 255-char string if needed
    change_column :gift_records, :memo, :string, limit: 255
    change_column :gift_people, :memo, :string, limit: 255
  end
end
