class AddPositionToGiftItemCategories < ActiveRecord::Migration[7.2]
  def change
    add_column :gift_item_categories, :position, :integer

     # 既存データにpositionを設定
    reversible do |dir|
      dir.up do
        GiftItemCategory.reset_column_information
        GiftItemCategory.find_each.with_index(1) do |category, index|
          category.update_column(:position, index)
        end
      end
    end

    # NOT NULL制約とインデックスを追加
    change_column_null :gift_item_categories, :position, false
    add_index :gift_item_categories, :position
  end
end
