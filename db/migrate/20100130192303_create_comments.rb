class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.text :text
	  t.float :ox_rank, :default => 0
	  t.integer :count, :default => 0
      t.references :user
	  t.references :post

      t.timestamps
    end
  end

  def self.down
    drop_table :comments
  end
end
