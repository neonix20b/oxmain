class AddCommentsToInvite < ActiveRecord::Migration
  def self.up
	add_column :comments, :invite_id, :integer
	add_column :comments, :vote_delete, :integer, :default=>0
  end

  def self.down
	remove_column :comments, :invite_id
	remove_column :comments, :vote_delete
  end
end
