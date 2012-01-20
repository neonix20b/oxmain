class Allclean < ActiveRecord::Migration
  def self.up
	remove_column :users, :last_comment_input
	remove_column :users, :last_post_input
	remove_column :users, :last_pm_input
	remove_column :users, :last_url
	remove_column :users, :count
	
	remove_column :posts, :user_id
	remove_column :comments, :user_id
	remove_column :users, :favorite
	remove_column :users, :right
	
	remove_column :users, :show_name
	remove_column :users, :old_rank
	remove_column :users, :last_vote
	remove_column :users, :avatar
	remove_column :users, :last_view
	remove_column :users, :last_posts
	remove_column :users, :gmtoffset
	rename_column :users, :login, :oxdomain 
	
	add_column :users, :email, :string
  end

  def self.down
	add_column :users, :last_comment_input, :text, :default => ""
	add_column :users, :last_post_input, :text, :default => ""
	add_column :users, :last_pm_input, :text, :default => ""
	add_column :users, :last_url, :string, :default => "/"
	add_column :users, :count, :integer, :default => 0
	
  	add_column :posts, :user_id, :integer, :default => 0
	add_column :comments, :user_id, :integer, :default => 0
	add_column :users, :favorite, :string
	add_column :users, :right, :string, :default => 'user'
	
	add_column :users, :show_name, :string
	add_column :users, :old_rank, :float, :default => 0
	add_column :users, :last_vote, :string, :default => 'none'
	add_column :users, :avatar, :string, :default => 'noavatar.png'
	add_column :users, :last_view, :timestamp, :default => Time.now
	add_column :users, :last_posts, :string
	add_column :users, :gmtoffset, :integer
	rename_column :users, :oxdomain, :login
	
	remove_column :users, :email
  end
end
