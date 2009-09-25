class AddAdeptField < ActiveRecord::Migration
  def self.up
	add_column :users, :right, :string, :default => 'user'
  end

  def self.down
	remove_column :users, :right
  end
end
