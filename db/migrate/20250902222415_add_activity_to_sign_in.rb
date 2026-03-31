class AddActivityToSignIn < ActiveRecord::Migration[7.1]
  def change
    add_column :sign_ins, :activity, :boolean, null: false, default: false
  end
end
