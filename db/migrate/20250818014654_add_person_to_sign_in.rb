class AddPersonToSignIn < ActiveRecord::Migration[8.0]
  def change
    add_reference :sign_ins, :person, null: false, foreign_key: true
  end
end
