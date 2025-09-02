class AddUniqueIndexToPeopleName < ActiveRecord::Migration[8.0]
  def change
    add_index :people, :name, unique: true
  end
end
