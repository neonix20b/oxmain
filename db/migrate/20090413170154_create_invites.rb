class CreateInvites < ActiveRecord::Migration
  def self.up
    create_table :invites do |t|
      t.references :user
      t.integer :invited_user
      t.string :invite_string
      t.timestamps
    end
  end

  def self.down
    drop_table :invites
  end
end
