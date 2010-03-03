class Friendconnect < ActiveRecord::Migration
  def self.up
	add_column :users, :friendconnect, :boolean, :default => false
  end

  def self.down
	remove_column :users, :boolean
  end
end
