class AddPositionToRelationships < ActiveRecord::Migration[7.2]
   def change
    add_column :relationships, :position, :integer, default: 0

    # 既存データにpositionを設定（オプション）
    reversible do |dir|
      dir.up do
        Relationship.reset_column_information
        Relationship.all.each_with_index do |relationship, index|
          relationship.update_column(:position, index + 1)
        end
      end
    end

    # インデックスを追加（パフォーマンス向上）
    add_index :relationships, :position
  end
end
