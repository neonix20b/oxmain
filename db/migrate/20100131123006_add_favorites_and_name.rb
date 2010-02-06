class AddFavoritesAndName < ActiveRecord::Migration
  def self.up
    add_column :users, :show_name, :string
    add_column :users, :favorite, :string
	
  end

  def self.down
    remove_column :users, :show_name
    remove_column :users, :favorite
  end
end
