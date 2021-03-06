class CreatePolls < ActiveRecord::Migration
  def self.up
    create_table :polls do |t|
      t.string :obj_id
      t.integer :profile_id
      t.boolean :vote
      t.timestamps
    end
  end

  def self.down
    drop_table :polls
  end
end
