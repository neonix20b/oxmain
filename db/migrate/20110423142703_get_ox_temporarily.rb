class GetOxTemporarily < ActiveRecord::Migration
  def self.up
	add_column :users, :delete_date, :timestamp, :default => Time.now
	add_column :users, :delete_bool, :boolean, :default => false
	add_column :users, :count, :integer, :default => 0
	add_column :invites, :delete_days, :integer, :default => 0
  end

  def self.down
	remove_column :users, :delete_date
	remove_column :users, :delete_bool
	remove_column :users, :count
	remove_column :invites, :delete_days
  end
end
