# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111015112717) do

  create_table "blogs", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", :force => true do |t|
    t.text     "text"
    t.float    "ox_rank",     :default => 0.0
    t.integer  "count",       :default => 0
    t.integer  "post_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "support_id"
    t.integer  "profile_id",  :default => 0
    t.integer  "invite_id"
    t.integer  "vote_delete", :default => 0
  end

  create_table "confs", :force => true do |t|
    t.string   "var"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invites", :force => true do |t|
    t.integer  "user_id"
    t.integer  "invited_user"
    t.string   "invite_string"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "text"
    t.string   "status"
    t.float    "ox_rank",       :default => 0.0
    t.integer  "count",         :default => 0
    t.integer  "blog_id"
    t.string   "title"
    t.integer  "spam",          :default => 0
    t.integer  "profile_id"
    t.integer  "delete_days",   :default => 0
  end

  create_table "oxservices", :force => true do |t|
    t.text     "description"
    t.string   "title"
    t.float    "cost"
    t.integer  "id_in_server"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "polices", :force => true do |t|
    t.string   "var"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "polls", :force => true do |t|
    t.string   "obj_id"
    t.integer  "profile_id"
    t.boolean  "vote"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "posts", :force => true do |t|
    t.string   "title"
    t.text     "text"
    t.float    "ox_rank",      :default => 0.0
    t.integer  "count",        :default => 0
    t.integer  "blog_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "last_comment"
    t.integer  "profile_id",   :default => 0
  end

  create_table "privatemessages", :force => true do |t|
    t.integer  "profile_from"
    t.integer  "profile_to"
    t.boolean  "readed",       :default => false
    t.text     "post"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "profiles", :force => true do |t|
    t.string   "email",                               :default => "",                    :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "",                    :null => false
    t.string   "password_salt",                       :default => "",                    :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",                     :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.text     "last_comment_input"
    t.text     "last_post_input"
    t.text     "last_pm_input"
    t.string   "last_url",                            :default => "/"
    t.integer  "count",                               :default => 0
    t.boolean  "admin",                               :default => false
    t.boolean  "adept",                               :default => false
    t.string   "show_name"
    t.string   "favorite"
    t.float    "old_rank",                            :default => 0.0
    t.float    "ox_rank",                             :default => 0.0
    t.string   "avatar",                              :default => "noavatar.png"
    t.datetime "last_view",                           :default => '2011-04-08 20:09:56'
    t.string   "last_posts"
    t.integer  "gmtoffset",                           :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "design",                              :default => ""
  end

  add_index "profiles", ["confirmation_token"], :name => "index_profiles_on_confirmation_token", :unique => true
  add_index "profiles", ["email"], :name => "index_profiles_on_email", :unique => true
  add_index "profiles", ["reset_password_token"], :name => "index_profiles_on_reset_password_token", :unique => true
  add_index "profiles", ["unlock_token"], :name => "index_profiles_on_unlock_token", :unique => true

  create_table "q", :primary_key => "number", :force => true do |t|
    t.integer "id"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

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

  create_table "supports", :force => true do |t|
    t.float    "money",      :default => 10.0
    t.string   "name"
    t.text     "info"
    t.text     "task"
    t.integer  "time",       :default => 30
    t.float    "ox_rank",    :default => 10.0
    t.integer  "user_id"
    t.integer  "worker_id"
    t.string   "status",     :default => "open"
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
    t.string   "oxdomain"
    t.string   "status",        :default => "0"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ftppass",       :default => "none"
    t.string   "mysqlpass",     :default => "none"
    t.string   "wtf",           :default => "joomla"
    t.string   "domain"
    t.float    "money",         :default => 0.0
    t.float    "ox_rank",       :default => 0.0
    t.integer  "profile_id",    :default => 0
    t.string   "email"
    t.datetime "delete_date",   :default => '2011-04-26 08:06:53'
    t.boolean  "delete_bool",   :default => false
    t.integer  "count",         :default => 0
    t.string   "attached_mail"
  end

end
