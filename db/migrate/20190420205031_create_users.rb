class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :name
      t.string :surname
      t.integer :occupation_id
      t.integer :state_id
      t.integer :department_id
      t.date :employed_since
      t.decimal :salary, precision: 6, scale: 2
      t.string :avatar_file_name
      t.string :email
      t.timestamps
    end
  end
end
