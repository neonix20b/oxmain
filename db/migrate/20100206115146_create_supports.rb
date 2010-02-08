class CreateSupports < ActiveRecord::Migration
  def self.up
    add_column :comments, :support_id, :integer
    create_table :supports do |t|
      t.float :money, :default => 10.0
      t.string :name
      t.text :info
      t.text :task
      t.integer :time, :default => 30
	  t.float :ox_rank, :default => 10
      t.references :user
      t.integer :worker_id
	  t.string :status, :default => 'open'
      t.timestamps
    end
  end
  
  def self.down
    drop_table :supports
    remove_column :comments, :support_id
  end
end
