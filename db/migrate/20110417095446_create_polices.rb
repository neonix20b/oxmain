class CreatePolices < ActiveRecord::Migration
  def self.up
    create_table :polices do |t|
      t.string :var
      t.string :value

      t.timestamps
    end
  end

  def self.down
    drop_table :polices
  end
end
