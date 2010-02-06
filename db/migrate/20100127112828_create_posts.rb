class CreatePosts < ActiveRecord::Migration
  def self.up
    add_column :users, :ox_rank, :float, :default => 0
    create_table :posts do |t|
      t.string :title
      t.text :text
      t.float :ox_rank, :default => 0
      t.integer :count, :default => 0
      t.references :blog
      t.references :user
      t.timestamps
    end
  end
  
  def self.down
    drop_table :posts
    remove_column :users, :ox_rank
  end
end
