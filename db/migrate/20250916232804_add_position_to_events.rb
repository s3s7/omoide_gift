class AddPositionToEvents < ActiveRecord::Migration[7.2]
   def change
    add_column :events, :position, :integer, default: 0, null: false
    add_index :events, :position

    # 既存レコードにposition値を設定
    reversible do |dir|
      dir.up do
        Event.reset_column_information
        Event.find_each.with_index(1) do |event, index|
          event.update_column(:position, index)
        end
      end
    end
  end
end
