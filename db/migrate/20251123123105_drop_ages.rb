class DropAges < ActiveRecord::Migration[7.2]
  def up
    drop_table :ages
  end

  def down
    create_table :ages do |t|
      t.string :year
      t.timestamps
    end
  end
end
