class CreateAges < ActiveRecord::Migration[7.2]
  def change
    create_table :ages do |t|
      t.string :year

      t.timestamps
    end
  end
end
