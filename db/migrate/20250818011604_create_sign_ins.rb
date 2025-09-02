class CreateSignIns < ActiveRecord::Migration[8.0]
  def change
    create_table :sign_ins do |t|
      t.timestamps
      t.datetime :left_at
      t.datetime :arrived_at
    end
  end
end
