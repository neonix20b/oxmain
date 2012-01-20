class AddDesign < ActiveRecord::Migration
  def self.up
	add_column :profiles, :design, :string, :default => ""
  end

  def self.down
	remove_column :profiles, :design
  end
end
