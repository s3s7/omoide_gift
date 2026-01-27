class RemoveGiftPeoplesImageFromGiftPeople < ActiveRecord::Migration[7.2]
  def change
    remove_column :gift_people, :gift_peoples_image, :string
  end
end
