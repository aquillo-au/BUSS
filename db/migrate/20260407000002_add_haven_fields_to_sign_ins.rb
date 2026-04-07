class AddHavenFieldsToSignIns < ActiveRecord::Migration[8.1]
  def change
    add_column :sign_ins, :phone_number, :string
    add_column :sign_ins, :car, :boolean, null: false, default: false
    add_column :sign_ins, :children, :integer, null: false, default: 0
    add_column :sign_ins, :pet, :boolean, null: false, default: false
    add_column :sign_ins, :notes, :text
    add_column :sign_ins, :is_haven_checkin, :boolean, null: false, default: false
  end
end
