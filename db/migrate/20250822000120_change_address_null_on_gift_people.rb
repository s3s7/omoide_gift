class ChangeAddressNullOnGiftPeople < ActiveRecord::Migration[7.2]
  def change
        change_column :gift_people, :address, :string, null: true, comment: '住所'
  end
end
