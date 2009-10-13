class CreateSmsbils < ActiveRecord::Migration
  def self.up
    create_table :smsbils do |t|
		t.string :country
		t.string :phone
		t.string :op_id
		t.string :op_name
		t.string :income
		t.string :price
		t.timestamps
    end
  end

  def self.down
    drop_table :smsbils
  end
end
