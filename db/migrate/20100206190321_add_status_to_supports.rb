class AddStatusToSupports < ActiveRecord::Migration
  def self.up
    add_column :supports, :status, :string, :default => 'open'
  end

  def self.down
    remove_column :supports, :support
  end
end
