# encoding: UTF-8
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

ActiveRecord::Schema.define(:version => 20120127234602) do

  create_table "arches", :id => false, :force => true do |t|
    t.integer  "id",         :null => false
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], :name => "index_arches_on_name", :unique => true
  end

  create_table "authentications", :id => false, :force => true do |t|
    t.integer  "id",         :null => false
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["provider", "uid"], :name => "index_authentications_on_provider_and_uid", :unique => true
    t.index ["user_id"], :name => "index_authentications_on_user_id"
  end

  create_table "auto_build_lists", :id => false, :force => true do |t|
    t.integer  "id",         :null => false
    t.integer  "project_id"
    t.integer  "arch_id"
    t.integer  "pl_id"
    t.integer  "bpl_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "build_list_items", :id => false, :force => true do |t|
    t.integer  "id",            :null => false
    t.string   "name"
    t.integer  "level"
    t.integer  "status"
    t.integer  "build_list_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "version"
    t.index ["build_list_id"], :name => "index_build_list_items_on_build_list_id"
  end

  create_table "build_lists", :id => false, :force => true do |t|
    t.integer  "id",                            :null => false
    t.integer  "bs_id"
    t.string   "container_path"
    t.integer  "status"
    t.string   "project_version"
    t.integer  "project_id"
    t.integer  "arch_id"
    t.datetime "notified_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "is_circle",        :limit => 2
    t.text     "additional_repos"
    t.string   "name"
    t.integer  "build_requires",   :limit => 2
    t.string   "update_type"
    t.integer  "bpl_id"
    t.integer  "pl_id"
    t.text     "include_repos"
    t.integer  "user_id"
    t.integer  "auto_publish",     :limit => 2
    t.string   "package_version"
    t.string   "commit_hash"
    t.index ["arch_id"], :name => "index_build_lists_on_arch_id"
    t.index ["bs_id"], :name => "index_build_lists_on_bs_id", :unique => true
    t.index ["project_id"], :name => "index_build_lists_on_project_id"
  end

  create_table "categories", :id => false, :force => true do |t|
    t.integer  "id",             :null => false
    t.string   "name"
    t.string   "ancestry"
    t.integer  "projects_count", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", :id => false, :force => true do |t|
    t.integer  "id",               :null => false
    t.string   "commentable_id"
    t.string   "commentable_type"
    t.integer  "user_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "containers", :id => false, :force => true do |t|
    t.integer  "id",         :null => false
    t.string   "name",       :null => false
    t.integer  "project_id", :null => false
    t.integer  "owner_id",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", :id => false, :force => true do |t|
    t.integer  "id",         :null => false
    t.integer  "priority"
    t.integer  "attempts"
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], :name => "delayed_jobs_priority"
  end

  create_table "downloads", :id => false, :force => true do |t|
    t.integer  "id",         :null => false
    t.string   "name",       :null => false
    t.string   "version"
    t.string   "distro"
    t.string   "platform"
    t.integer  "counter"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "event_logs", :id => false, :force => true do |t|
    t.integer  "id",          :null => false
    t.integer  "user_id"
    t.string   "user_name"
    t.integer  "object_id"
    t.string   "object_type"
    t.string   "object_name"
    t.string   "ip"
    t.string   "kind"
    t.string   "protocol"
    t.string   "controller"
    t.string   "action"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups", :id => false, :force => true do |t|
    t.integer  "id",                 :null => false
    t.string   "name"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uname"
    t.integer  "own_projects_count", :null => false
  end

  create_table "issues", :id => false, :force => true do |t|
    t.integer  "id",         :null => false
    t.integer  "serial_id"
    t.integer  "project_id"
    t.integer  "user_id"
    t.string   "title"
    t.text     "body"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["project_id", "serial_id"], :name => "index_issues_on_project_id_and_serial_id", :unique => true
  end

  create_table "platforms", :id => false, :force => true do |t|
    t.integer  "id",                              :null => false
    t.string   "description"
    t.string   "name"
    t.integer  "parent_platform_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "released",           :limit => 2
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "visibility"
    t.string   "platform_type"
    t.string   "distrib_type"
  end

  create_table "private_users", :id => false, :force => true do |t|
    t.integer  "id",          :null => false
    t.integer  "platform_id"
    t.string   "login"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "product_build_lists", :id => false, :force => true do |t|
    t.integer  "id",          :null => false
    t.integer  "product_id"
    t.integer  "status",      :null => false
    t.datetime "notified_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["product_id"], :name => "index_product_build_lists_on_product_id"
  end

  create_table "products", :id => false, :force => true do |t|
    t.integer  "id",                            :null => false
    t.string   "name",                          :null => false
    t.integer  "platform_id",                   :null => false
    t.integer  "build_status",                  :null => false
    t.string   "build_path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "build_script"
    t.text     "counter"
    t.text     "ks"
    t.text     "menu"
    t.string   "tar_file_name"
    t.string   "tar_content_type"
    t.integer  "tar_file_size"
    t.datetime "tar_updated_at"
    t.integer  "is_template",      :limit => 2
    t.integer  "system_wide",      :limit => 2
    t.text     "cron_tab"
    t.integer  "use_cron",         :limit => 2
  end

  create_table "project_imports", :id => false, :force => true do |t|
    t.integer  "id",         :null => false
    t.integer  "project_id"
    t.string   "name"
    t.string   "version"
    t.datetime "file_mtime"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], :name => "index_project_imports_on_name", :unique => true
    t.index ["project_id"], :name => "index_project_imports_on_project_id"
  end

  create_table "project_to_repositories", :id => false, :force => true do |t|
    t.integer  "id",            :null => false
    t.integer  "project_id"
    t.integer  "repository_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", :id => false, :force => true do |t|
    t.integer  "id",                             :null => false
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "visibility"
    t.integer  "category_id"
    t.text     "description"
    t.string   "ancestry"
    t.integer  "has_wiki",          :limit => 2
    t.integer  "has_issues",        :limit => 2
    t.integer  "srpm_file_size"
    t.string   "srpm_file_name"
    t.string   "srpm_content_type"
    t.datetime "srpm_updated_at"
    t.index ["category_id"], :name => "index_projects_on_category_id"
    t.index ["name", "owner_id", "owner_type"], :name => "index_projects_on_name_and_owner_id_and_owner_type", :unique => true
  end

  create_table "relations", :id => false, :force => true do |t|
    t.integer  "id",          :null => false
    t.integer  "object_id"
    t.string   "object_type"
    t.integer  "target_id"
    t.string   "target_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "role"
  end

  create_table "repositories", :id => false, :force => true do |t|
    t.integer  "id",          :null => false
    t.string   "description", :null => false
    t.integer  "platform_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",        :null => false
    t.integer  "owner_id"
    t.string   "owner_type"
  end

  create_table "role_lines", :id => false, :force => true do |t|
    t.integer  "id",          :null => false
    t.integer  "role_id"
    t.integer  "relation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :id => false, :force => true do |t|
    t.integer  "id",         :null => false
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rpms", :id => false, :force => true do |t|
    t.integer  "id",         :null => false
    t.string   "name",       :null => false
    t.integer  "arch_id",    :null => false
    t.integer  "project_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["project_id"], :name => "index_rpms_on_project_id"
    t.index ["project_id", "arch_id"], :name => "index_rpms_on_project_id_and_arch_id"
  end

  create_table "settings_notifiers", :id => false, :force => true do |t|
    t.integer  "id",                             :null => false
    t.integer  "user_id",                        :null => false
    t.integer  "can_notify",        :limit => 2
    t.integer  "new_comment",       :limit => 2
    t.integer  "new_comment_reply", :limit => 2
    t.integer  "new_issue",         :limit => 2
    t.integer  "issue_assign",      :limit => 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subscribes", :id => false, :force => true do |t|
    t.integer  "id",                 :null => false
    t.integer  "subscribeable_id"
    t.string   "subscribeable_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :id => false, :force => true do |t|
    t.integer  "id",                                  :null => false
    t.string   "name"
    t.string   "email",                               :null => false
    t.string   "encrypted_password",   :limit => 128, :null => false
    t.string   "password_salt",                       :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "ssh_key"
    t.string   "uname"
    t.string   "role"
    t.integer  "own_projects_count",                  :null => false
    t.string   "language"
    t.index ["email"], :name => "index_users_on_email", :unique => true
    t.index ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
    t.index ["uname"], :name => "index_users_on_uname", :unique => true
  end

end
