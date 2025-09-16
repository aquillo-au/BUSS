class AddArchivedToPeople < ActiveRecord::Migration[7.1]
  def change
    add_column :people, :archived, :boolean, null: false, default: false
    add_index :people, :archived
  end
end
