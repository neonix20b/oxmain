class AddMoney < ActiveRecord::Migration
  def self.up
    add_column :users, :money, :float, :default => 0
  end

  def self.down
    remove_column :users, :money
  end
end
