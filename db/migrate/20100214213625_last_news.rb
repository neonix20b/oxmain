class LastNews < ActiveRecord::Migration
  def self.up
  	add_column :posts, :last_comment, :string
	add_column :users, :last_view, :timestamp, :default => Time.now
	add_column :users, :last_posts, :string
  end

  def self.down
	remove_column :posts, :last_comment
	remove_column :users, :last_view
	remove_column :users, :last_posts
  end
end
