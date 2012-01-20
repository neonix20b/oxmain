class AddProfileIdToInvites < ActiveRecord::Migration
  def self.up
	add_column :invites, :profile_id, :integer
  end

  def self.down
	remove_column :invites, :profile_id
  end
end
