class AddForum < ActiveRecord::Migration
  def self.up
    add_column :users, :wtf, :string, :default => 'joomla'
  end

  def self.down
    remove_column :users, :wtf
  end
end
