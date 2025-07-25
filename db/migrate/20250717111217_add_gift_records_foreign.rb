class Add < ActiveRecord::Migration[7.2]
  def change
    add_reference :gift_records, :age, foreign_key: true
  end
end
