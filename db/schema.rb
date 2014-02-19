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

ActiveRecord::Schema.define(:version => 20140219191644) do

  create_table "activity_feeds", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "kind"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activity_feeds", ["user_id", "kind"], :name => "index_activity_feeds_on_user_id_and_kind"

  create_table "advisories", :force => true do |t|
    t.string   "advisory_id"
    t.text     "description", :default => ""
    t.text     "references",  :default => ""
    t.text     "update_type", :default => ""
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
  end

  add_index "advisories", ["advisory_id"], :name => "index_advisories_on_advisory_id", :unique => true
  add_index "advisories", ["update_type"], :name => "index_advisories_on_update_type"

  create_table "advisories_platforms", :id => false, :force => true do |t|
    t.integer "advisory_id"
    t.integer "platform_id"
  end

  add_index "advisories_platforms", ["advisory_id"], :name => "index_advisories_platforms_on_advisory_id"
  add_index "advisories_platforms", ["advisory_id", "platform_id"], :name => "advisory_platform_index", :unique => true
  add_index "advisories_platforms", ["platform_id"], :name => "index_advisories_platforms_on_platform_id"

  create_table "advisories_projects", :id => false, :force => true do |t|
    t.integer "advisory_id"
    t.integer "project_id"
  end

  add_index "advisories_projects", ["advisory_id"], :name => "index_advisories_projects_on_advisory_id"
  add_index "advisories_projects", ["advisory_id", "project_id"], :name => "advisory_project_index", :unique => true
  add_index "advisories_projects", ["project_id"], :name => "index_advisories_projects_on_project_id"

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
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.boolean  "actual",        :default => false
    t.string   "sha1"
    t.integer  "epoch"
  end

  add_index "build_list_packages", ["actual", "platform_id"], :name => "index_build_list_packages_on_actual_and_platform_id"
  add_index "build_list_packages", ["build_list_id"], :name => "index_build_list_packages_on_build_list_id"
  add_index "build_list_packages", ["name", "project_id"], :name => "index_build_list_packages_on_name_and_project_id"
  add_index "build_list_packages", ["platform_id"], :name => "index_build_list_packages_on_platform_id"
  add_index "build_list_packages", ["project_id"], :name => "index_build_list_packages_on_project_id"

  create_table "build_lists", :force => true do |t|
    t.integer  "status"
    t.string   "project_version"
    t.integer  "project_id"
    t.integer  "arch_id"
    t.datetime "notified_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_circle",                     :default => false
    t.text     "additional_repos"
    t.string   "name"
    t.string   "update_type"
    t.integer  "build_for_platform_id"
    t.integer  "save_to_platform_id"
    t.text     "include_repos"
    t.integer  "user_id"
    t.string   "package_version"
    t.string   "commit_hash"
    t.integer  "priority",                      :default => 0,         :null => false
    t.datetime "started_at"
    t.integer  "duration"
    t.integer  "advisory_id"
    t.integer  "mass_build_id"
    t.integer  "save_to_repository_id"
    t.text     "results"
    t.boolean  "new_core",                      :default => true
    t.string   "last_published_commit_hash"
    t.integer  "container_status"
    t.boolean  "auto_create_container",         :default => false
    t.text     "extra_repositories"
    t.text     "extra_build_lists"
    t.integer  "publisher_id"
    t.integer  "group_id"
    t.text     "extra_params"
    t.string   "external_nodes"
    t.integer  "builder_id"
    t.boolean  "include_testing_subrepository"
    t.string   "auto_publish_status",           :default => "default", :null => false
  end

  add_index "build_lists", ["advisory_id"], :name => "index_build_lists_on_advisory_id"
  add_index "build_lists", ["arch_id"], :name => "index_build_lists_on_arch_id"
  add_index "build_lists", ["project_id", "save_to_repository_id", "build_for_platform_id", "arch_id"], :name => "maintainer_search_index"
  add_index "build_lists", ["project_id"], :name => "index_build_lists_on_project_id"

  create_table "comments", :force => true do |t|
    t.string   "commentable_type"
    t.integer  "user_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "commentable_id",           :precision => 50, :scale => 0
    t.integer  "project_id"
    t.text     "data"
    t.boolean  "automatic",                                               :default => false
    t.decimal  "created_from_commit_hash", :precision => 50, :scale => 0
    t.integer  "created_from_issue_id"
  end

  add_index "comments", ["automatic"], :name => "index_comments_on_automatic"
  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
  add_index "comments", ["commentable_type"], :name => "index_comments_on_commentable_type"
  add_index "comments", ["created_from_commit_hash"], :name => "index_comments_on_created_from_commit_hash"
  add_index "comments", ["created_from_issue_id"], :name => "index_comments_on_created_from_issue_id"

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

  create_table "flash_notifies", :force => true do |t|
    t.text     "body_ru",                      :null => false
    t.text     "body_en",                      :null => false
    t.string   "status",                       :null => false
    t.boolean  "published",  :default => true, :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  create_table "groups", :force => true do |t|
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uname"
    t.integer  "own_projects_count",  :default => 0, :null => false
    t.text     "description"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
  end

  create_table "hooks", :force => true do |t|
    t.text     "data"
    t.integer  "project_id"
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
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
  add_index "issues", ["user_id"], :name => "index_issues_on_user_id"

  create_table "key_pairs", :force => true do |t|
    t.text     "public",           :null => false
    t.text     "encrypted_secret", :null => false
    t.string   "key_id",           :null => false
    t.integer  "user_id",          :null => false
    t.integer  "repository_id",    :null => false
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "key_pairs", ["repository_id"], :name => "index_key_pairs_on_repository_id", :unique => true

  create_table "key_pairs_backup", :force => true do |t|
    t.integer  "repository_id", :null => false
    t.integer  "user_id",       :null => false
    t.string   "key_id",        :null => false
    t.text     "public",        :null => false
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "key_pairs_backup", ["repository_id"], :name => "index_key_pairs_backup_on_repository_id", :unique => true

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
    t.integer  "build_for_platform_id",                    :null => false
    t.string   "name"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.string   "arch_names"
    t.integer  "user_id"
    t.boolean  "auto_publish",          :default => false, :null => false
    t.integer  "build_lists_count",     :default => 0,     :null => false
    t.integer  "build_published_count", :default => 0,     :null => false
    t.integer  "build_pending_count",   :default => 0,     :null => false
    t.integer  "build_started_count",   :default => 0,     :null => false
    t.integer  "build_publish_count",   :default => 0,     :null => false
    t.integer  "build_error_count",     :default => 0,     :null => false
    t.boolean  "stop_build",            :default => false, :null => false
    t.text     "projects_list"
    t.integer  "missed_projects_count", :default => 0,     :null => false
    t.text     "missed_projects_list"
    t.boolean  "new_core",              :default => true
    t.integer  "success_count",         :default => 0,     :null => false
    t.integer  "build_canceled_count",  :default => 0,     :null => false
    t.integer  "save_to_platform_id",                      :null => false
    t.text     "extra_repositories"
    t.text     "extra_build_lists"
    t.boolean  "increase_release_tag",  :default => false, :null => false
  end

  create_table "platform_arch_settings", :force => true do |t|
    t.integer  "platform_id", :null => false
    t.integer  "arch_id",     :null => false
    t.integer  "time_living", :null => false
    t.boolean  "default"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "platform_arch_settings", ["platform_id", "arch_id"], :name => "index_platform_arch_settings_on_platform_id_and_arch_id", :unique => true

  create_table "platforms", :force => true do |t|
    t.string   "description"
    t.string   "name",                                                :null => false
    t.integer  "parent_platform_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "released",                        :default => false,  :null => false
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "visibility",                      :default => "open", :null => false
    t.string   "platform_type",                   :default => "main", :null => false
    t.string   "distrib_type",                                        :null => false
    t.integer  "status"
    t.datetime "last_regenerated_at"
    t.integer  "last_regenerated_status"
    t.string   "last_regenerated_log_sha1"
    t.string   "automatic_metadata_regeneration"
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
    t.integer  "status",                             :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
    t.string   "project_version"
    t.string   "commit_hash"
    t.string   "params"
    t.string   "main_script"
    t.text     "results"
    t.integer  "arch_id"
    t.integer  "time_living"
    t.integer  "user_id"
    t.boolean  "not_delete",      :default => false
    t.boolean  "autostarted",     :default => false
  end

  add_index "product_build_lists", ["product_id"], :name => "index_product_build_lists_on_product_id"

  create_table "products", :force => true do |t|
    t.string   "name",             :null => false
    t.integer  "platform_id",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.integer  "project_id"
    t.string   "params"
    t.string   "main_script"
    t.integer  "time_living"
    t.integer  "autostart_status"
    t.string   "project_version"
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

  create_table "project_statistics", :force => true do |t|
    t.integer  "average_build_time", :default => 0, :null => false
    t.integer  "build_count",        :default => 0, :null => false
    t.integer  "arch_id",                           :null => false
    t.integer  "project_id",                        :null => false
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  add_index "project_statistics", ["project_id", "arch_id"], :name => "index_project_statistics_on_project_id_and_arch_id", :unique => true

  create_table "project_tags", :force => true do |t|
    t.integer  "project_id"
    t.string   "commit_id"
    t.string   "sha1"
    t.string   "tag_name"
    t.integer  "format_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "project_to_repositories", :force => true do |t|
    t.integer  "project_id"
    t.integer  "repository_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.hstore   "autostart_options"
  end

  add_index "project_to_repositories", ["repository_id", "project_id"], :name => "index_project_to_repositories_on_repository_id_and_project_id", :unique => true

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "visibility",               :default => "open"
    t.text     "description"
    t.string   "ancestry"
    t.boolean  "has_issues",               :default => true
    t.string   "srpm_file_name"
    t.integer  "srpm_file_size"
    t.datetime "srpm_updated_at"
    t.string   "srpm_content_type"
    t.boolean  "has_wiki",                 :default => false
    t.string   "default_branch",           :default => "master"
    t.boolean  "is_package",               :default => true,     :null => false
    t.integer  "maintainer_id"
    t.boolean  "publish_i686_into_x86_64", :default => false
    t.string   "owner_uname",                                    :null => false
    t.boolean  "architecture_dependent",   :default => false,    :null => false
    t.integer  "autostart_status"
  end

  add_index "projects", ["owner_id", "name", "owner_type"], :name => "index_projects_on_name_and_owner_id_and_owner_type", :unique => true, :case_sensitive => false

  create_table "pull_requests", :force => true do |t|
    t.integer "issue_id",                 :null => false
    t.integer "to_project_id",            :null => false
    t.integer "from_project_id",          :null => false
    t.string  "to_ref",                   :null => false
    t.string  "from_ref",                 :null => false
    t.string  "from_project_owner_uname"
    t.string  "from_project_name"
  end

  add_index "pull_requests", ["from_project_id"], :name => "index_pull_requests_on_head_project_id"
  add_index "pull_requests", ["issue_id"], :name => "index_pull_requests_on_issue_id"
  add_index "pull_requests", ["to_project_id"], :name => "index_pull_requests_on_base_project_id"

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
    t.string   "language"
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

  add_index "relations", ["actor_type", "actor_id"], :name => "index_relations_on_actor_type_and_actor_id"
  add_index "relations", ["target_type", "target_id"], :name => "index_relations_on_target_type_and_target_id"

  create_table "repositories", :force => true do |t|
    t.string   "description",                                   :null => false
    t.integer  "platform_id",                                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                                          :null => false
    t.boolean  "publish_without_qa",         :default => true
    t.boolean  "synchronizing_publications", :default => false, :null => false
  end

  add_index "repositories", ["platform_id"], :name => "index_repositories_on_platform_id"

  create_table "repository_statuses", :force => true do |t|
    t.integer  "repository_id",                            :null => false
    t.integer  "platform_id",                              :null => false
    t.integer  "status",                    :default => 0
    t.datetime "last_regenerated_at"
    t.integer  "last_regenerated_status"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.string   "last_regenerated_log_sha1"
  end

  add_index "repository_statuses", ["repository_id", "platform_id"], :name => "index_repository_statuses_on_repository_id_and_platform_id", :unique => true

  create_table "settings_notifiers", :force => true do |t|
    t.integer  "user_id",                                          :null => false
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
    t.boolean  "new_build",                     :default => true
    t.boolean  "new_associated_build",          :default => true
    t.boolean  "update_code",                   :default => false
  end

  create_table "ssh_keys", :force => true do |t|
    t.string   "name"
    t.text     "key",         :null => false
    t.string   "fingerprint", :null => false
    t.integer  "user_id",     :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "ssh_keys", ["fingerprint"], :name => "index_ssh_keys_on_fingerprint", :unique => true
  add_index "ssh_keys", ["user_id"], :name => "index_ssh_keys_on_user_id"

  create_table "subscribes", :force => true do |t|
    t.string   "subscribeable_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "status",                                            :default => true
    t.integer  "project_id"
    t.decimal  "subscribeable_id",   :precision => 50, :scale => 0
  end

  create_table "tokens", :force => true do |t|
    t.integer  "subject_id",                                 :null => false
    t.string   "subject_type",                               :null => false
    t.integer  "creator_id",                                 :null => false
    t.integer  "updater_id"
    t.string   "status",               :default => "active"
    t.text     "description"
    t.string   "authentication_token",                       :null => false
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
  end

  add_index "tokens", ["authentication_token"], :name => "index_tokens_on_authentication_token", :unique => true
  add_index "tokens", ["subject_id", "subject_type"], :name => "index_tokens_on_subject_id_and_subject_type"

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email",                                  :default => "",   :null => false
    t.string   "encrypted_password",      :limit => 128, :default => "",   :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "ssh_key"
    t.string   "uname"
    t.string   "role"
    t.string   "language",                               :default => "en"
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
    t.boolean  "sound_notifications",                    :default => true
  end

  add_index "users", ["authentication_token"], :name => "index_users_on_authentication_token"
  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["uname"], :name => "index_users_on_uname", :unique => true
  add_index "users", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true

end
