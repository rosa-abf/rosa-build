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

ActiveRecord::Schema.define(:version => 20110317130503) do

  create_table "arches", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "arches", ["name"], :name => "index_arches_on_name", :unique => true

  create_table "containers", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "project_id", :null => false
    t.integer  "owner_id",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "platforms", :force => true do |t|
    t.string   "name"
    t.string   "unixname"
    t.integer  "parent_platform_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "released",           :default => false
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.string   "unixname"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "repository_id", :null => false
  end

  create_table "repositories", :force => true do |t|
    t.string   "name",        :null => false
    t.integer  "platform_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "unixname",    :null => false
  end

  create_table "rpms", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "arch_id",    :null => false
    t.integer  "project_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rpms", ["project_id", "arch_id"], :name => "index_rpms_on_project_id_and_arch_id"
  add_index "rpms", ["project_id"], :name => "index_rpms_on_project_id"

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email",                               :default => "", :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "", :null => false
    t.string   "password_salt",                       :default => "", :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
