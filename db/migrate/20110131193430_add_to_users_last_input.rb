class AddToUsersLastInput < ActiveRecord::Migration
  def self.up
	add_column :users, :last_comment_input, :text, :default => ""
	add_column :users, :last_post_input, :text, :default => ""
	add_column :users, :last_pm_input, :text, :default => ""
	add_column :users, :last_url, :string, :default => "/"
  end

  def self.down
	remove_column :users, :last_comment_input
	remove_column :users, :last_post_input
	remove_column :users, :last_pm_input
	remove_column :users, :last_url
  end
end
