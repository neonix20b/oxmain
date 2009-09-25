class AddFtpMysql < ActiveRecord::Migration
  def self.up
    add_column :users, :ftppass, :string, :default => 'none'
    add_column :users, :mysqlpass, :string, :default => 'none'
  end

  def self.down
    remove_column :users, :ftppass
    remove_column :users, :mysqlpass
  end
end
