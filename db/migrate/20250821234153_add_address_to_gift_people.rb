class AddAddressToGiftPeople < ActiveRecord::Migration[7.2]
  def change
    add_column :gift_people, :address, :string
  end
end
