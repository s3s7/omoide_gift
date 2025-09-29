class AddCommentableToGiftRecords < ActiveRecord::Migration[7.2]
 def change
    # デフォルト値をtrueに設定し、NOT NULL制約も追加
    add_column :gift_records, :commentable, :boolean, default: true, null: false

    # 既存レコードに対してもデフォルト値を明示的に設定（安全のため）
    # この行は既存データがある場合に重要です
    # reversible do |dir|
    #   dir.up do
    #     # マイグレーション実行時：既存レコードをすべてコメント可能に設定
    #     GiftRecord.update_all(commentable: true)
    #   end
    # end
  end
end
