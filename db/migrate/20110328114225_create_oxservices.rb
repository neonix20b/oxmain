class CreateOxservices < ActiveRecord::Migration
  def self.up
    create_table :oxservices do |t|
      t.text :description
      t.string :title
      t.float :cost
	  t.integer :id_in_server
      t.timestamps
    end
	remove_column :users, :email
	remove_column :users, :crypted_password
	remove_column :users, :salt
	remove_column :users, :remember_token
	remove_column :users, :remember_token_expires_at
  end

  def self.down
    drop_table :oxservices
	add_column :users, :email, :string
	add_column :users, :crypted_password, :string
	add_column :users, :salt, :string
	add_column :users, :remember_token, :timestamp
	add_column :users, :remember_token_expires_at, :timestamp
  end
end
