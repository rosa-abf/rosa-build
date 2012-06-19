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

ActiveRecord::Schema.define(:version => 20120609163454) do

  create_table "activity_feeds", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "kind"
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "advisories", :force => true do |t|
    t.string   "advisory_id"
    t.integer  "project_id"
    t.text     "description", :default => ""
    t.text     "references",  :default => ""
    t.text     "update_type", :default => ""
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
  end

  add_index "advisories", ["advisory_id"], :name => "index_advisories_on_advisory_id", :unique => true
  add_index "advisories", ["project_id"], :name => "index_advisories_on_project_id"
  add_index "advisories", ["update_type"], :name => "index_advisories_on_update_type"

  create_table "advisories_platforms", :id => false, :force => true do |t|
    t.integer "advisory_id"
    t.integer "platform_id"
  end

  add_index "advisories_platforms", ["advisory_id"], :name => "index_advisories_platforms_on_advisory_id"
  add_index "advisories_platforms", ["advisory_id", "platform_id"], :name => "advisory_platform_index", :unique => true
  add_index "advisories_platforms", ["platform_id"], :name => "index_advisories_platforms_on_platform_id"

  create_table "arches", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "arches", ["name"], :name => "index_arches_on_name", :unique => true

  create_table "authentications", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "authentications", ["provider", "uid"], :name => "index_authentications_on_provider_and_uid", :unique => true
  add_index "authentications", ["user_id"], :name => "index_authentications_on_user_id"

  create_table "build_list_items", :force => true do |t|
    t.string   "name"
    t.integer  "level"
    t.integer  "status"
    t.integer  "build_list_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "version"
  end

  add_index "build_list_items", ["build_list_id"], :name => "index_build_list_items_on_build_list_id"

  create_table "build_list_packages", :force => true do |t|
    t.integer  "build_list_id"
    t.integer  "project_id"
    t.integer  "platform_id"
    t.string   "fullname"
    t.string   "name"
    t.string   "version"
    t.string   "release"
    t.string   "package_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "build_list_packages", ["build_list_id"], :name => "index_build_list_packages_on_build_list_id"
  add_index "build_list_packages", ["platform_id"], :name => "index_build_list_packages_on_platform_id"
  add_index "build_list_packages", ["project_id"], :name => "index_build_list_packages_on_project_id"

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
    t.boolean  "is_circle",             :default => false
    t.text     "additional_repos"
    t.string   "name"
    t.boolean  "build_requires",        :default => false
    t.string   "update_type"
    t.integer  "build_for_platform_id"
    t.integer  "save_to_platform_id"
    t.text     "include_repos"
    t.integer  "user_id"
    t.boolean  "auto_publish",          :default => true
    t.string   "package_version"
    t.string   "commit_hash"
    t.integer  "priority",              :default => 0,     :null => false
    t.datetime "started_at"
    t.integer  "duration"
    t.integer  "advisory_id"
    t.integer  "mass_build_id"
  end

  add_index "build_lists", ["advisory_id"], :name => "index_build_lists_on_advisory_id"
  add_index "build_lists", ["arch_id"], :name => "index_build_lists_on_arch_id"
  add_index "build_lists", ["bs_id"], :name => "index_build_lists_on_bs_id", :unique => true
  add_index "build_lists", ["project_id"], :name => "index_build_lists_on_project_id"

  create_table "comments", :force => true do |t|
    t.string   "commentable_type"
    t.integer  "user_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "commentable_id",   :precision => 50, :scale => 0
    t.integer  "project_id"
  end

  create_table "event_logs", :force => true do |t|
    t.integer  "user_id"
    t.string   "user_name"
    t.integer  "eventable_id"
    t.string   "eventable_type"
    t.string   "eventable_name"
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
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uname"
    t.integer  "own_projects_count", :default => 0, :null => false
    t.text     "description"
  end

  create_table "issues", :force => true do |t|
    t.integer  "serial_id"
    t.integer  "project_id"
    t.integer  "assignee_id"
    t.string   "title"
    t.text     "body"
    t.string   "status",      :default => "open"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.datetime "closed_at"
    t.integer  "closed_by"
  end

  add_index "issues", ["project_id", "serial_id"], :name => "index_issues_on_project_id_and_serial_id", :unique => true

  create_table "labelings", :force => true do |t|
    t.integer  "label_id",   :null => false
    t.integer  "issue_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "labelings", ["issue_id"], :name => "index_labelings_on_issue_id"

  create_table "labels", :force => true do |t|
    t.string   "name",       :null => false
    t.string   "color",      :null => false
    t.integer  "project_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "labels", ["project_id"], :name => "index_labels_on_project_id"

  create_table "mass_builds", :force => true do |t|
    t.integer  "platform_id"
    t.string   "name"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.string   "arch_names"
    t.integer  "user_id"
    t.boolean  "auto_publish", :default => false, :null => false
  end

  create_table "platforms", :force => true do |t|
    t.string   "description"
    t.string   "name",                                   :null => false
    t.integer  "parent_platform_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "released",           :default => false,  :null => false
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "visibility",         :default => "open", :null => false
    t.string   "platform_type",      :default => "main", :null => false
    t.string   "distrib_type",                           :null => false
  end

  add_index "platforms", ["name"], :name => "index_platforms_on_name", :unique => true, :case_sensitive => false

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
  end

  add_index "product_build_lists", ["product_id"], :name => "index_product_build_lists_on_product_id"

  create_table "products", :force => true do |t|
    t.string   "name",                                :null => false
    t.integer  "platform_id",                         :null => false
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
    t.text     "cron_tab"
    t.boolean  "use_cron",         :default => false
    t.text     "description"
  end

  create_table "project_imports", :force => true do |t|
    t.integer  "project_id"
    t.string   "name"
    t.string   "version"
    t.datetime "file_mtime"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "platform_id"
  end

  add_index "project_imports", ["platform_id", "name"], :name => "index_project_imports_on_name_and_platform_id", :unique => true, :case_sensitive => false

  create_table "project_to_repositories", :force => true do |t|
    t.integer  "project_id"
    t.integer  "repository_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "visibility",         :default => "open"
    t.text     "description"
    t.string   "ancestry"
    t.boolean  "has_issues",         :default => true
    t.string   "srpm_file_name"
    t.string   "srpm_content_type"
    t.integer  "srpm_file_size"
    t.datetime "srpm_updated_at"
    t.boolean  "has_wiki",           :default => false
    t.string   "default_branch",     :default => "master"
    t.boolean  "is_package",         :default => true,     :null => false
    t.integer  "average_build_time", :default => 0,        :null => false
    t.integer  "build_count",        :default => 0,        :null => false
  end

  add_index "projects", ["owner_id"], :name => "index_projects_on_name_and_owner_id_and_owner_type", :unique => true, :case_sensitive => false

  create_table "register_requests", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "token"
    t.boolean  "approved",   :default => false
    t.boolean  "rejected",   :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "interest"
    t.text     "more"
  end

  add_index "register_requests", ["email"], :name => "index_register_requests_on_email", :unique => true, :case_sensitive => false
  add_index "register_requests", ["token"], :name => "index_register_requests_on_token", :unique => true, :case_sensitive => false

  create_table "relations", :force => true do |t|
    t.integer  "actor_id"
    t.string   "actor_type"
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
  end

  create_table "settings_notifiers", :force => true do |t|
    t.integer  "user_id",                                         :null => false
    t.boolean  "can_notify",                    :default => true
    t.boolean  "new_comment",                   :default => true
    t.boolean  "new_comment_reply",             :default => true
    t.boolean  "new_issue",                     :default => true
    t.boolean  "issue_assign",                  :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "new_comment_commit_owner",      :default => true
    t.boolean  "new_comment_commit_repo_owner", :default => true
    t.boolean  "new_comment_commit_commentor",  :default => true
  end

  create_table "subscribes", :force => true do |t|
    t.string   "subscribeable_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "status",                                            :default => true
    t.integer  "project_id"
    t.decimal  "subscribeable_id",   :precision => 50, :scale => 0
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email",                                  :default => "",   :null => false
    t.string   "encrypted_password",      :limit => 128, :default => "",   :null => false
    t.string   "reset_password_token"
    t.datetime "remember_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uname"
    t.string   "role"
    t.string   "language",                               :default => "en"
    t.datetime "reset_password_sent_at"
    t.integer  "own_projects_count",                     :default => 0,    :null => false
    t.text     "professional_experience"
    t.string   "site"
    t.string   "company"
    t.string   "location"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer  "failed_attempts",                        :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "authentication_token"
    t.integer  "build_priority",                         :default => 50
  end

  add_index "users", ["authentication_token"], :name => "index_users_on_authentication_token"
  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["uname"], :name => "index_users_on_uname", :unique => true
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true

end
