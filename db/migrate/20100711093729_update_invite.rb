class UpdateInvite < ActiveRecord::Migration
  def self.up
		add_column :invites, :text, :text
		add_column :invites, :status, :string
		add_column :invites, :ox_rank, :float, :default => 0
		add_column :invites, :count, :integer, :default => 0
		add_column :invites, :blog_id, :integer
		add_column :invites, :title, :string
		add_column :invites, :spam, :integer, :default => 0
  end

  def self.down
		remove_column :invites, :text
		remove_column :invites, :status
		remove_column :invites, :ox_rank
		remove_column :invites, :count
		remove_column :invites, :blog_id
		remove_column :invites, :title
		remove_column :invites, :spam
  end
end
