class CreatePeople < ActiveRecord::Migration[8.0]
  def change
    create_table :people do |t|
      t.string :name,     null: false
      t.string :email
      t.string :phone
      t.boolean :volunteer, default: false
      t.boolean :present, default: false

      t.timestamps
    end
  end
end
