class AddHavenFieldsToSignIns < ActiveRecord::Migration[8.0]
  def change
    add_column :sign_ins, :is_haven_checkin, :boolean, default: false, null: false
    add_column :sign_ins, :checked_in_at, :datetime
    add_column :sign_ins, :checked_out_at, :datetime
    add_column :sign_ins, :has_car, :boolean
    add_column :sign_ins, :num_children, :integer
    add_column :sign_ins, :has_pet, :boolean
    add_column :sign_ins, :haven_notes, :text
  end
end
