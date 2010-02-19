class Gmtoffset < ActiveRecord::Migration
  def self.up
	add_column :users, :gmtoffset, :integer
  end

  def self.down
	remove_column :users, :gmtoffset
  end
end
