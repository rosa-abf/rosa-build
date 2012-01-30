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

  create_table "arches", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], :name => "index_arches_on_name", :unique => true
  end

  create_table "authentications", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["provider", "uid"], :name => "index_authentications_on_provider_and_uid", :unique => true
    t.index ["user_id"], :name => "index_authentications_on_user_id"
  end

  create_table "auto_build_lists", :force => true do |t|
    t.integer  "project_id"
    t.integer  "arch_id"
    t.integer  "pl_id"
    t.integer  "bpl_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "build_list_items", :force => true do |t|
    t.string   "name"
    t.integer  "level"
    t.integer  "status"
    t.integer  "build_list_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "version"
    t.index ["build_list_id"], :name => "index_build_list_items_on_build_list_id"
  end

  create_table "build_lists", :force => true do |t|
    t.integer  "bs_id"
    t.string   "container_path"
    t.integer  "status"
    t.string   "project_version"
    t.integer  "project_id"
    t.integer  "arch_id"
    t.datetime "notified_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_circle",        :default => false
    t.text     "additional_repos"
    t.string   "name"
    t.boolean  "build_requires",   :default => false
    t.string   "update_type"
    t.integer  "bpl_id"
    t.integer  "pl_id"
    t.text     "include_repos"
    t.integer  "user_id"
    t.boolean  "auto_publish",     :default => true
    t.string   "package_version"
    t.string   "commit_hash"
    t.index ["bs_id"], :name => "index_build_lists_on_bs_id", :unique => true
    t.index ["arch_id"], :name => "index_build_lists_on_arch_id"
    t.index ["project_id"], :name => "index_build_lists_on_project_id"
  end

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.string   "ancestry"
    t.integer  "projects_count", :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", :force => true do |t|
    t.string   "commentable_id"
    t.string   "commentable_type"
    t.integer  "user_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "containers", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "project_id", :null => false
    t.integer  "owner_id",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
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

  create_table "downloads", :force => true do |t|
    t.string   "name",                      :null => false
    t.string   "version"
    t.string   "distro"
    t.string   "platform"
    t.integer  "counter",    :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "event_logs", :force => true do |t|
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

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uname"
    t.integer  "own_projects_count", :default => 0, :null => false
  end

  create_table "issues", :force => true do |t|
    t.integer  "serial_id"
    t.integer  "project_id"
    t.integer  "user_id"
    t.string   "title"
    t.text     "body"
    t.string   "status",     :default => "open"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["project_id", "serial_id"], :name => "index_issues_on_project_id_and_serial_id", :unique => true
  end

  create_table "platforms", :force => true do |t|
    t.string   "description"
    t.string   "name"
    t.integer  "parent_platform_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "released",           :default => false
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "visibility",         :default => "open"
    t.string   "platform_type",      :default => "main"
    t.string   "distrib_type"
  end

  create_table "private_users", :force => true do |t|
    t.integer  "platform_id"
    t.string   "login"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "product_build_lists", :force => true do |t|
    t.integer  "product_id"
    t.integer  "status",      :default => 2, :null => false
    t.datetime "notified_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["product_id"], :name => "index_product_build_lists_on_product_id"
  end

  create_table "products", :force => true do |t|
    t.string   "name",                                :null => false
    t.integer  "platform_id",                         :null => false
    t.integer  "build_status",     :default => 2,     :null => false
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
    t.boolean  "is_template",      :default => false
    t.boolean  "system_wide",      :default => false
    t.text     "cron_tab"
    t.boolean  "use_cron",         :default => false
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "visibility",        :default => "open"
    t.integer  "category_id"
    t.text     "description"
    t.string   "ancestry"
    t.boolean  "has_wiki"
    t.boolean  "has_issues",        :default => true
    t.integer  "srpm_file_size"
    t.string   "srpm_file_name"
    t.string   "srpm_content_type"
    t.datetime "srpm_updated_at"
    t.index ["name", "owner_id", "owner_type"], :name => "index_projects_on_name_and_owner_id_and_owner_type", :unique => true
    t.index ["category_id"], :name => "index_projects_on_category_id"
  end

  create_table "project_imports", :force => true do |t|
    t.integer  "project_id"
    t.string   "name"
    t.string   "version"
    t.datetime "file_mtime"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], :name => "index_project_imports_on_name", :unique => true
    t.index ["project_id"], :name => "index_project_imports_on_project_id"
    t.foreign_key ["project_id"], "projects", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "project_imports_ibfk_1"
  end

  create_table "project_to_repositories", :force => true do |t|
    t.integer  "project_id"
    t.integer  "repository_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "relations", :force => true do |t|
    t.integer  "object_id"
    t.string   "object_type"
    t.integer  "target_id"
    t.string   "target_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "role"
  end

  create_table "repositories", :force => true do |t|
    t.string   "description", :null => false
    t.integer  "platform_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",        :null => false
    t.integer  "owner_id"
    t.string   "owner_type"
  end

  create_table "role_lines", :force => true do |t|
    t.integer  "role_id"
    t.integer  "relation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rpms", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "arch_id",    :null => false
    t.integer  "project_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["project_id", "arch_id"], :name => "index_rpms_on_project_id_and_arch_id"
    t.index ["project_id"], :name => "index_rpms_on_project_id"
  end

  create_table "settings_notifiers", :force => true do |t|
    t.integer  "user_id",                             :null => false
    t.boolean  "can_notify",        :default => true
    t.boolean  "new_comment",       :default => true
    t.boolean  "new_comment_reply", :default => true
    t.boolean  "new_issue",         :default => true
    t.boolean  "issue_assign",      :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subscribes", :force => true do |t|
    t.integer  "subscribeable_id"
    t.string   "subscribeable_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email",                               :default => "",   :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "",   :null => false
    t.string   "password_salt",                       :default => "",   :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "ssh_key"
    t.string   "uname"
    t.string   "role"
    t.integer  "own_projects_count",                  :default => 0,    :null => false
    t.string   "language",                            :default => "en"
    t.index ["email"], :name => "index_users_on_email", :unique => true
    t.index ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
    t.index ["uname"], :name => "index_users_on_uname", :unique => true
  end

end
