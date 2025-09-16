class AddVolunteerToSignIn < ActiveRecord::Migration[7.1]
  def change
    add_column :sign_ins, :volunteer, :boolean, null: false, default: false
  end
end
