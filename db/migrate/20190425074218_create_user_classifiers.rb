class CreateUserClassifiers < ActiveRecord::Migration[5.2]
  def change
    create_table :user_classifiers do |t|
      t.string :type
      t.boolean :is_system, default: false
      t.boolean :is_active, default: true
      t.datetime :created_at
      t.datetime :updated_at
      t.string :color
      t.integer :position, limit: 4, null: false
      t.string :key
      t.timestamps
    end
  end
end
