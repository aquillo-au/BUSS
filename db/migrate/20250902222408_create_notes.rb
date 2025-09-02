class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.integer :info
      t.integer :amount

      t.timestamps
    end
  end
end
