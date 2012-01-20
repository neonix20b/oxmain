class DeviseCreateProfiles < ActiveRecord::Migration
  def self.up
    create_table(:profiles) do |t|
      t.database_authenticatable :null => false
      t.recoverable
      t.rememberable
      t.trackable

      t.confirmable
      t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      t.token_authenticatable

      t.text :last_comment_input, :default => ""
      t.text :last_post_input, :default => ""
      t.text :last_pm_input, :default => ""
      t.string :last_url, :default => "/"
	  t.integer :count, :default => 0
	  t.boolean :admin, :default=>false
	  t.boolean :adept, :default=>false
	  t.string :show_name
	  t.string :favorite
	  
	  t.float :old_rank, :default => 0
	  t.float :ox_rank, :default => 0
	  #t.string, :last_vote, :default => 'none'
	  t.string :avatar, :default => 'noavatar.png'
	  t.timestamp :last_view, :default => Time.now
	  t.string :last_posts
	  t.integer :gmtoffset, :default=>0

      t.timestamps
    end
    add_index :profiles, :email,                :unique => true
    add_index :profiles, :reset_password_token, :unique => true
    add_index :profiles, :confirmation_token,   :unique => true
    add_index :profiles, :unlock_token,         :unique => true
	add_column :users, :profile_id, :integer, :default => 0
	add_column :posts, :profile_id, :integer, :default => 0
	add_column :comments, :profile_id, :integer, :default => 0
	
  end

  def self.down
	drop_table :profiles
	remove_column :users, :profile_id
	remove_column :posts, :profile_id
	remove_column :comments, :profile_id
  end
end
