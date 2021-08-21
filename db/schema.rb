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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20210823145116) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "activity_feeds", force: :cascade do |t|
    t.integer  "user_id",       :null=>false, :index=>{:name=>"index_activity_feeds_on_user_id_and_kind", :with=>["kind"]}
    t.string   "kind",          :limit=>255
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "project_owner", :limit=>255, :index=>{:name=>"index_activity_feeds_on_project_owner"}
    t.string   "project_name",  :limit=>255, :index=>{:name=>"index_activity_feeds_on_project_name"}
    t.integer  "creator_id",    :index=>{:name=>"index_activity_feeds_on_creator_id"}
  end

  create_table "advisories", force: :cascade do |t|
    t.string   "advisory_id", :limit=>255, :index=>{:name=>"index_advisories_on_advisory_id", :unique=>true}
    t.text     "description", :default=>""
    t.text     "references",  :default=>""
    t.text     "update_type", :default=>"", :index=>{:name=>"index_advisories_on_update_type"}
    t.datetime "created_at",  :null=>false
    t.datetime "updated_at",  :null=>false
  end

  create_table "platforms", force: :cascade do |t|
    t.string   "description",                     :limit=>255
    t.string   "name",                            :limit=>255, :null=>false, :index=>{:name=>"index_platforms_on_name", :unique=>true, :case_sensitive=>false}
    t.integer  "parent_platform_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "released",                        :default=>false, :null=>false
    t.integer  "owner_id"
    t.string   "owner_type",                      :limit=>255
    t.string   "visibility",                      :limit=>255, :default=>"open", :null=>false
    t.string   "platform_type",                   :limit=>255, :default=>"main", :null=>false
    t.string   "distrib_type",                    :limit=>255, :null=>false
    t.integer  "status"
    t.datetime "last_regenerated_at"
    t.integer  "last_regenerated_status"
    t.string   "last_regenerated_log_sha1",       :limit=>255
    t.string   "automatic_metadata_regeneration", :limit=>255
    t.string   "default_branch",                  :limit=>255, :null=>false
  end

  create_table "projects", force: :cascade do |t|
    t.string   "name",                     :limit=>255, :index=>{:name=>"index_projects_on_name_and_owner_id_and_owner_type", :with=>["owner_id", "owner_type"], :unique=>true, :case_sensitive=>false}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type",               :limit=>255
    t.string   "visibility",               :limit=>255, :default=>"open"
    t.text     "description"
    t.string   "ancestry",                 :limit=>255
    t.boolean  "has_issues",               :default=>true
    t.string   "srpm_file_name",           :limit=>255
    t.integer  "srpm_file_size"
    t.datetime "srpm_updated_at"
    t.string   "srpm_content_type",        :limit=>255
    t.string   "default_branch",           :limit=>255, :default=>"master"
    t.boolean  "is_package",               :default=>true, :null=>false
    t.integer  "maintainer_id"
    t.boolean  "publish_i686_into_x86_64", :default=>false
    t.string   "owner_uname",              :limit=>255, :null=>false
    t.boolean  "architecture_dependent",   :default=>false, :null=>false
    t.integer  "autostart_status"
    t.integer  "alias_from_id",            :index=>{:name=>"index_projects_on_alias_from_id"}
  end

  create_table "advisory_items", force: :cascade do |t|
    t.integer "advisory_id", :index=>{:name=>"index_advisory_items_on_advisory_id"}, :foreign_key=>{:references=>"advisories", :name=>"fk_advisory_items_advisory_id", :on_update=>:no_action, :on_delete=>:no_action}
    t.integer "platform_id", :index=>{:name=>"index_advisory_items_on_platform_id"}, :foreign_key=>{:references=>"platforms", :name=>"fk_advisory_items_platform_id", :on_update=>:no_action, :on_delete=>:no_action}
    t.integer "project_id",  :index=>{:name=>"index_advisory_items_on_project_id"}, :foreign_key=>{:references=>"projects", :name=>"fk_advisory_items_project_id", :on_update=>:no_action, :on_delete=>:no_action}
  end
  add_index "advisory_items", ["advisory_id", "platform_id", "project_id"], :name=>"unique_platform_project", :unique=>true

  create_table "ar_internal_metadata", primary_key: "key", force: :cascade do |t|
    t.string   "value"
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "arches", force: :cascade do |t|
    t.string   "name",       :limit=>255, :null=>false, :index=>{:name=>"index_arches_on_name", :unique=>true}
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "build_list_items", force: :cascade do |t|
    t.string   "name",          :limit=>255
    t.integer  "level"
    t.integer  "status"
    t.integer  "build_list_id", :index=>{:name=>"index_build_list_items_on_build_list_id"}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "version",       :limit=>255
  end

  create_table "build_list_packages", force: :cascade do |t|
    t.integer  "build_list_id",      :index=>{:name=>"index_build_list_packages_on_build_list_id"}
    t.integer  "project_id",         :index=>{:name=>"index_build_list_packages_on_project_id"}
    t.integer  "platform_id",        :index=>{:name=>"index_build_list_packages_on_platform_id"}
    t.string   "fullname",           :limit=>255
    t.string   "name",               :limit=>255, :index=>{:name=>"index_build_list_packages_on_name_and_project_id", :with=>["project_id"]}
    t.string   "version",            :limit=>255
    t.string   "release",            :limit=>255
    t.string   "package_type",       :limit=>255
    t.datetime "created_at",         :null=>false
    t.datetime "updated_at",         :null=>false
    t.boolean  "actual",             :default=>false, :index=>{:name=>"index_build_list_packages_on_actual_and_platform_id", :with=>["platform_id"]}
    t.string   "sha1",               :limit=>255
    t.integer  "epoch"
    t.text     "dependent_packages"
    t.integer  "size",               :limit=>8, :default=>0
    t.index :name=>"build_list_packages_ordering", :expression=>"lower((name)::text), length((name)::text)"
  end

  create_table "build_lists", force: :cascade do |t|
    t.integer  "status"
    t.string   "project_version",               :limit=>255
    t.integer  "project_id",                    :index=>{:name=>"index_build_lists_on_project_id"}
    t.integer  "arch_id",                       :index=>{:name=>"index_build_lists_on_arch_id"}
    t.datetime "notified_at"
    t.datetime "created_at"
    t.datetime "updated_at",                    :index=>{:name=>"index_build_lists_on_updated_at", :order=>{"updated_at"=>:desc}}
    t.boolean  "is_circle",                     :default=>false
    t.text     "additional_repos"
    t.string   "name",                          :limit=>255
    t.string   "update_type",                   :limit=>255
    t.integer  "build_for_platform_id"
    t.integer  "save_to_platform_id"
    t.text     "include_repos"
    t.integer  "user_id",                       :index=>{:name=>"index_build_lists_on_user_id"}
    t.string   "package_version",               :limit=>255
    t.string   "commit_hash",                   :limit=>255
    t.integer  "priority",                      :default=>0, :null=>false
    t.datetime "started_at"
    t.integer  "duration"
    t.integer  "advisory_id",                   :index=>{:name=>"index_build_lists_on_advisory_id"}
    t.integer  "mass_build_id",                 :index=>{:name=>"index_build_lists_on_mass_build_id_and_status", :with=>["status"]}
    t.integer  "save_to_repository_id"
    t.text     "results"
    t.boolean  "new_core",                      :default=>true
    t.string   "last_published_commit_hash",    :limit=>255
    t.integer  "container_status"
    t.boolean  "auto_create_container",         :default=>false
    t.text     "extra_repositories"
    t.text     "extra_build_lists"
    t.integer  "publisher_id"
    t.integer  "group_id"
    t.text     "extra_params"
    t.string   "external_nodes",                :limit=>255
    t.integer  "builder_id"
    t.boolean  "include_testing_subrepository"
    t.string   "auto_publish_status",           :limit=>255, :default=>"default", :null=>false
    t.boolean  "use_cached_chroot",             :default=>false, :null=>false
    t.boolean  "use_extra_tests",               :default=>true, :null=>false
    t.boolean  "save_buildroot",                :default=>false, :null=>false
    t.string   "hostname"
    t.string   "fail_reason"
  end
  add_index "build_lists", ["project_id", "save_to_repository_id", "build_for_platform_id", "arch_id"], :name=>"maintainer_search_index"

  create_table "comments", force: :cascade do |t|
    t.string   "commentable_type",         :limit=>255, :index=>{:name=>"index_comments_on_commentable_type"}
    t.integer  "user_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "commentable_id",           :precision=>50, :index=>{:name=>"index_comments_on_commentable_id"}
    t.integer  "project_id"
    t.text     "data"
    t.boolean  "automatic",                :default=>false, :index=>{:name=>"index_comments_on_automatic"}
    t.decimal  "created_from_commit_hash", :precision=>50, :index=>{:name=>"index_comments_on_created_from_commit_hash"}
    t.integer  "created_from_issue_id",    :index=>{:name=>"index_comments_on_created_from_issue_id"}
  end

  create_table "event_logs", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "user_name",      :limit=>255
    t.integer  "eventable_id"
    t.string   "eventable_type", :limit=>255
    t.string   "eventable_name", :limit=>255
    t.string   "ip",             :limit=>255
    t.string   "kind",           :limit=>255
    t.string   "protocol",       :limit=>255
    t.string   "controller",     :limit=>255
    t.string   "action",         :limit=>255
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "flash_notifies", force: :cascade do |t|
    t.text     "body_ru",    :null=>false
    t.text     "body_en",    :null=>false
    t.string   "status",     :limit=>255, :null=>false
    t.boolean  "published",  :default=>true, :null=>false
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "groups", force: :cascade do |t|
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uname",               :limit=>255
    t.integer  "own_projects_count",  :default=>0, :null=>false
    t.text     "description"
    t.string   "avatar_file_name",    :limit=>255
    t.string   "avatar_content_type", :limit=>255
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string   "default_branch",      :limit=>255
  end

  create_table "hooks", force: :cascade do |t|
    t.text     "data"
    t.integer  "project_id"
    t.string   "name",       :limit=>255
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "users", force: :cascade do |t|
    t.string   "name",                    :limit=>255
    t.string   "email",                   :limit=>255, :default=>"", :null=>false, :index=>{:name=>"index_users_on_email", :unique=>true}
    t.string   "encrypted_password",      :limit=>128, :default=>"", :null=>false
    t.string   "reset_password_token",    :limit=>255, :index=>{:name=>"index_users_on_reset_password_token", :unique=>true}
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "ssh_key"
    t.string   "uname",                   :limit=>255, :index=>{:name=>"index_users_on_uname", :unique=>true}
    t.string   "role",                    :limit=>255
    t.string   "language",                :limit=>255, :default=>"en"
    t.integer  "own_projects_count",      :default=>0, :null=>false
    t.text     "professional_experience"
    t.string   "site",                    :limit=>255
    t.string   "company",                 :limit=>255
    t.string   "location",                :limit=>255
    t.string   "avatar_file_name",        :limit=>255
    t.string   "avatar_content_type",     :limit=>255
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer  "failed_attempts",         :default=>0
    t.string   "unlock_token",            :limit=>255, :index=>{:name=>"index_users_on_unlock_token", :unique=>true}
    t.datetime "locked_at"
    t.string   "confirmation_token",      :limit=>255, :index=>{:name=>"index_users_on_confirmation_token", :unique=>true}
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "authentication_token",    :limit=>255, :index=>{:name=>"index_users_on_authentication_token"}
    t.integer  "build_priority",          :default=>50
    t.boolean  "sound_notifications",     :default=>true
    t.boolean  "hide_email",              :default=>true, :null=>false
  end

  create_table "invites", force: :cascade do |t|
    t.integer  "user_id",         :null=>false, :index=>{:name=>"index_invites_on_user_id"}, :foreign_key=>{:references=>"users", :name=>"fk_invites_user_id", :on_update=>:no_action, :on_delete=>:no_action}
    t.integer  "invited_user_id", :index=>{:name=>"index_invites_on_invited_user_id"}
    t.string   "invite_key",      :default=>"", :index=>{:name=>"index_invites_on_invite_key"}
    t.datetime "created_at",      :null=>false
    t.datetime "updated_at",      :null=>false
  end

  create_table "issues", force: :cascade do |t|
    t.integer  "serial_id"
    t.integer  "project_id",  :index=>{:name=>"index_issues_on_project_id_and_serial_id", :with=>["serial_id"], :unique=>true}
    t.integer  "assignee_id"
    t.string   "title",       :limit=>255
    t.text     "body"
    t.string   "status",      :limit=>255, :default=>"open"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",     :index=>{:name=>"index_issues_on_user_id"}
    t.datetime "closed_at"
    t.integer  "closed_by"
  end

  create_table "key_pairs", force: :cascade do |t|
    t.text     "public",              :null=>false
    t.text     "encrypted_secret",    :null=>false
    t.string   "key_id",              :limit=>255, :null=>false
    t.integer  "user_id",             :null=>false
    t.integer  "repository_id",       :null=>false, :index=>{:name=>"index_key_pairs_on_repository_id", :unique=>true}
    t.datetime "created_at",          :null=>false
    t.datetime "updated_at",          :null=>false
    t.string   "encrypted_secret_iv", :index=>{:name=>"index_key_pairs_on_encrypted_secret_iv", :unique=>true}
  end

  create_table "labelings", force: :cascade do |t|
    t.integer  "label_id",   :null=>false
    t.integer  "issue_id",   :index=>{:name=>"index_labelings_on_issue_id"}
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "labels", force: :cascade do |t|
    t.string   "name",       :limit=>255, :null=>false
    t.string   "color",      :limit=>255, :null=>false
    t.integer  "project_id", :index=>{:name=>"index_labels_on_project_id"}
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "mass_builds", force: :cascade do |t|
    t.integer  "build_for_platform_id",         :null=>false
    t.string   "name",                          :limit=>255
    t.datetime "created_at",                    :null=>false
    t.datetime "updated_at",                    :null=>false
    t.string   "arch_names",                    :limit=>255
    t.integer  "user_id"
    t.integer  "build_lists_count",             :default=>0, :null=>false
    t.boolean  "stop_build",                    :default=>false, :null=>false
    t.text     "projects_list"
    t.integer  "missed_projects_count",         :default=>0, :null=>false
    t.text     "missed_projects_list"
    t.boolean  "new_core",                      :default=>true
    t.integer  "save_to_platform_id",           :null=>false
    t.text     "extra_repositories"
    t.text     "extra_build_lists"
    t.boolean  "increase_release_tag",          :default=>false, :null=>false
    t.boolean  "use_cached_chroot",             :default=>true, :null=>false
    t.boolean  "use_extra_tests",               :default=>false, :null=>false
    t.string   "description",                   :limit=>255
    t.string   "auto_publish_status",           :limit=>255, :default=>"none", :null=>false
    t.text     "extra_mass_builds"
    t.boolean  "include_testing_subrepository", :default=>false, :null=>false
    t.boolean  "auto_create_container",         :default=>false, :null=>false
    t.integer  "status",                        :default=>2000, :null=>false
    t.string   "external_nodes",                :limit=>255
  end

  create_table "platform_arch_settings", force: :cascade do |t|
    t.integer  "platform_id", :null=>false, :index=>{:name=>"index_platform_arch_settings_on_platform_id_and_arch_id", :with=>["arch_id"], :unique=>true}
    t.integer  "arch_id",     :null=>false
    t.integer  "time_living", :null=>false
    t.boolean  "default"
    t.datetime "created_at",  :null=>false
    t.datetime "updated_at",  :null=>false
  end

  create_table "product_build_lists", force: :cascade do |t|
    t.integer  "product_id",      :index=>{:name=>"index_product_build_lists_on_product_id"}
    t.integer  "status",          :null=>false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
    t.string   "project_version", :limit=>255
    t.string   "commit_hash",     :limit=>255
    t.string   "params",          :limit=>255
    t.string   "main_script",     :limit=>255
    t.text     "results"
    t.integer  "arch_id"
    t.integer  "time_living"
    t.integer  "user_id"
    t.boolean  "not_delete",      :default=>false
    t.boolean  "autostarted",     :default=>false
  end

  create_table "products", force: :cascade do |t|
    t.string   "name",             :limit=>255, :null=>false
    t.integer  "platform_id",      :null=>false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.integer  "project_id"
    t.string   "params",           :limit=>255
    t.string   "main_script",      :limit=>255
    t.integer  "time_living"
    t.integer  "autostart_status"
    t.string   "project_version",  :limit=>255
  end

  create_table "project_imports", force: :cascade do |t|
    t.integer  "project_id"
    t.string   "name",        :limit=>255, :index=>{:name=>"index_project_imports_on_name_and_platform_id", :with=>["platform_id"], :unique=>true, :case_sensitive=>false}
    t.string   "version",     :limit=>255
    t.datetime "file_mtime"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "platform_id"
  end

  create_table "project_statistics", force: :cascade do |t|
    t.integer  "average_build_time", :default=>0, :null=>false
    t.integer  "build_count",        :default=>0, :null=>false
    t.integer  "arch_id",            :null=>false
    t.integer  "project_id",         :null=>false, :index=>{:name=>"index_project_statistics_on_project_id_and_arch_id", :with=>["arch_id"], :unique=>true}
    t.datetime "created_at",         :null=>false
    t.datetime "updated_at",         :null=>false
  end

  create_table "project_tags", force: :cascade do |t|
    t.integer  "project_id"
    t.string   "commit_id",  :limit=>255
    t.string   "sha1",       :limit=>255
    t.string   "tag_name",   :limit=>255
    t.integer  "format_id"
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "project_to_repositories", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "repository_id",     :index=>{:name=>"index_project_to_repositories_on_repository_id_and_project_id", :with=>["project_id"], :unique=>true}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.hstore   "autostart_options"
  end

  create_table "pull_requests", force: :cascade do |t|
    t.integer "issue_id",                 :null=>false, :index=>{:name=>"index_pull_requests_on_issue_id"}
    t.integer "to_project_id",            :null=>false, :index=>{:name=>"index_pull_requests_on_base_project_id"}
    t.integer "from_project_id",          :null=>false, :index=>{:name=>"index_pull_requests_on_head_project_id"}
    t.string  "to_ref",                   :limit=>255, :null=>false
    t.string  "from_ref",                 :limit=>255, :null=>false
    t.string  "from_project_owner_uname", :limit=>255
    t.string  "from_project_name",        :limit=>255
  end

  create_table "relations", force: :cascade do |t|
    t.integer  "actor_id"
    t.string   "actor_type",  :limit=>255, :index=>{:name=>"index_relations_on_actor_type_and_actor_id", :with=>["actor_id"]}
    t.integer  "target_id"
    t.string   "target_type", :limit=>255, :index=>{:name=>"index_relations_on_target_type_and_target_id", :with=>["target_id"]}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "role",        :limit=>255
  end

  create_table "repositories", force: :cascade do |t|
    t.string   "description",                     :limit=>255, :null=>false
    t.integer  "platform_id",                     :null=>false, :index=>{:name=>"index_repositories_on_platform_id"}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                            :limit=>255, :null=>false
    t.boolean  "publish_without_qa",              :default=>true
    t.boolean  "synchronizing_publications",      :default=>false, :null=>false
    t.string   "publish_builds_only_from_branch", :limit=>255
  end

  create_table "repository_statuses", force: :cascade do |t|
    t.integer  "repository_id",             :null=>false, :index=>{:name=>"index_repository_statuses_on_repository_id_and_platform_id", :with=>["platform_id"], :unique=>true}
    t.integer  "platform_id",               :null=>false
    t.integer  "status",                    :default=>0
    t.datetime "last_regenerated_at"
    t.integer  "last_regenerated_status"
    t.datetime "created_at",                :null=>false
    t.datetime "updated_at",                :null=>false
    t.string   "last_regenerated_log_sha1", :limit=>255
    t.boolean  "resign_rpms",               :default=>false
  end

  create_table "settings_notifiers", force: :cascade do |t|
    t.integer  "user_id",                       :null=>false
    t.boolean  "can_notify",                    :default=>true
    t.boolean  "new_comment",                   :default=>true
    t.boolean  "new_comment_reply",             :default=>true
    t.boolean  "new_issue",                     :default=>true
    t.boolean  "issue_assign",                  :default=>true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "new_comment_commit_owner",      :default=>true
    t.boolean  "new_comment_commit_repo_owner", :default=>true
    t.boolean  "new_comment_commit_commentor",  :default=>true
    t.boolean  "new_build",                     :default=>true
    t.boolean  "new_associated_build",          :default=>true
    t.boolean  "update_code",                   :default=>false
  end

  create_table "ssh_keys", force: :cascade do |t|
    t.string   "name",        :limit=>255
    t.text     "key",         :null=>false
    t.string   "fingerprint", :limit=>255, :null=>false, :index=>{:name=>"index_ssh_keys_on_fingerprint", :unique=>true}
    t.integer  "user_id",     :null=>false, :index=>{:name=>"index_ssh_keys_on_user_id"}
    t.datetime "created_at",  :null=>false
    t.datetime "updated_at",  :null=>false
  end

  create_table "statistics", force: :cascade do |t|
    t.integer  "user_id",                 :null=>false, :index=>{:name=>"index_statistics_on_user_id"}
    t.string   "email",                   :limit=>255, :null=>false
    t.integer  "project_id",              :null=>false, :index=>{:name=>"index_statistics_on_project_id"}
    t.string   "project_name_with_owner", :limit=>255, :null=>false
    t.string   "key",                     :limit=>255, :null=>false, :index=>{:name=>"index_statistics_on_key"}
    t.integer  "counter",                 :default=>0, :null=>false
    t.datetime "activity_at",             :null=>false, :index=>{:name=>"index_statistics_on_activity_at"}
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "statistics", ["key", "activity_at"], :name=>"index_statistics_on_key_and_activity_at"
  add_index "statistics", ["project_id", "key", "activity_at"], :name=>"index_statistics_on_project_id_and_key_and_activity_at"
  add_index "statistics", ["user_id", "key", "activity_at"], :name=>"index_statistics_on_user_id_and_key_and_activity_at"
  add_index "statistics", ["user_id", "project_id", "key", "activity_at"], :name=>"index_statistics_on_all_keys", :unique=>true

  create_table "subscribes", force: :cascade do |t|
    t.string   "subscribeable_type", :limit=>255
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "status",             :default=>true
    t.integer  "project_id"
    t.decimal  "subscribeable_id",   :precision=>50
  end

  create_table "tokens", force: :cascade do |t|
    t.integer  "subject_id",           :null=>false, :index=>{:name=>"index_tokens_on_subject_id_and_subject_type", :with=>["subject_type"]}
    t.string   "subject_type",         :limit=>255, :null=>false
    t.integer  "creator_id",           :null=>false
    t.integer  "updater_id"
    t.string   "status",               :limit=>255, :default=>"active"
    t.text     "description"
    t.string   "authentication_token", :limit=>255, :null=>false, :index=>{:name=>"index_tokens_on_authentication_token", :unique=>true}
    t.datetime "created_at",           :null=>false
    t.datetime "updated_at",           :null=>false
  end

  create_table "user_builds_settings", force: :cascade do |t|
    t.integer "user_id",        :null=>false, :index=>{:name=>"index_user_builds_settings_on_user_id", :unique=>true}
    t.text    "platforms",      :default=>[], :null=>false, :array=>true
    t.string  "external_nodes", :limit=>255
  end

end
