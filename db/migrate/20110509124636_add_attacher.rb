class AddAttacher < ActiveRecord::Migration
  def self.up
	add_column :users, :attached_mail, :string
  end

  def self.down
	remove_column :users, :attached_mail
  end
end
