class CreateClassifierPermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :classifier_permissions do |t|
      t.references :user, index: true
      t.references :user_classifier, index: true
    end
  end
end
