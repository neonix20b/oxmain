class CreatePrivatemessages < ActiveRecord::Migration
  def self.up
    create_table :privatemessages do |t|
      t.integer	:profile_from
	  t.integer	:profile_to
	  t.boolean	:readed, :default=>false
      t.text :post

      t.timestamps
    end
  end

  def self.down
    drop_table :privatemessages
  end
end
