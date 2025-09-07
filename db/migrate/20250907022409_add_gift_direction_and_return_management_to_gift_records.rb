class AddGiftDirectionAndReturnManagementToGiftRecords < ActiveRecord::Migration[7.2]
  def change
    # ギフトの方向性（もらった/あげた）
    add_column :gift_records, :gift_direction, :integer, default: 0, null: false, comment: 'ギフトの方向性（received/given）'

    # お返しギフト管理
    add_column :gift_records, :parent_gift_record_id, :bigint, null: true, comment: 'お返し元のギフトレコードID'
    add_column :gift_records, :is_return_gift, :boolean, default: false, null: false, comment: 'お返しギフトかどうか'

    # お返し状況管理（もらったギフトのみ）
    add_column :gift_records, :needs_return, :boolean, default: false, null: false, comment: 'お返しが必要かどうか'
    add_column :gift_records, :return_status, :integer, default: 0, null: false, comment: 'お返し状況'
    add_column :gift_records, :return_deadline, :date, null: true, comment: 'お返し期限'

    # インデックス追加
    add_index :gift_records, :gift_direction
    add_index :gift_records, :parent_gift_record_id
    add_index :gift_records, :is_return_gift
    add_index :gift_records, :needs_return
    add_index :gift_records, :return_status
    add_index :gift_records, [ :gift_direction, :needs_return ], name: 'index_gift_records_on_direction_and_return'
    add_index :gift_records, [ :needs_return, :return_status ], name: 'index_gift_records_on_return_management'

    # 外部キー制約
    add_foreign_key :gift_records, :gift_records, column: :parent_gift_record_id
  end
end
