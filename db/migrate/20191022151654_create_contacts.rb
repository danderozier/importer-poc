class CreateContacts < ActiveRecord::Migration[5.2]
  def change
    create_table :contacts do |t|
      t.string :address
      t.string :email
      t.string :member_id
      t.string :name
      t.string :organization

      t.timestamps
    end
  end
end
