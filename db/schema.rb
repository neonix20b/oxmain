# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091013150152) do

  create_table "invites", :force => true do |t|
    t.integer  "user_id"
    t.integer  "invited_user"
    t.string   "invite_string"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "smsbils", :force => true do |t|
    t.string   "country"
    t.string   "phone"
    t.string   "op_id"
    t.string   "op_name"
    t.string   "income"
    t.string   "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "tasks", :force => true do |t|
    t.integer  "user_id"
    t.string   "status"
    t.string   "domain"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "status",                                  :default => "0"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "ftppass",                                 :default => "none"
    t.string   "mysqlpass",                               :default => "none"
    t.string   "wtf",                                     :default => "joomla"
    t.string   "domain"
    t.float    "money",                                   :default => 0.0
    t.string   "right",                                   :default => "user"
  end

end
