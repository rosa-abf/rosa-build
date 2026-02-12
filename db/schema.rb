# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_11_071212) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "pg_catalog.plpgsql"

  create_table "activity_feeds", force: :cascade do |t|
    t.datetime "created_at"
    t.integer "creator_id"
    t.text "data"
    t.string "kind", limit: 255
    t.string "project_name", limit: 255
    t.string "project_owner", limit: 255
    t.datetime "updated_at"
    t.integer "user_id", null: false
    t.index ["creator_id"], name: "index_activity_feeds_on_creator_id"
    t.index ["project_name"], name: "index_activity_feeds_on_project_name"
    t.index ["project_owner"], name: "index_activity_feeds_on_project_owner"
    t.index ["user_id"], name: "index_activity_feeds_on_user_id_and_kind"
  end

  create_table "advisories", force: :cascade do |t|
    t.string "advisory_id", limit: 255
    t.datetime "created_at", null: false
    t.text "description", default: ""
    t.text "references", default: ""
    t.text "update_type", default: ""
    t.datetime "updated_at", null: false
    t.index ["advisory_id"], name: "index_advisories_on_advisory_id", unique: true
    t.index ["update_type"], name: "index_advisories_on_update_type"
  end

  create_table "advisory_items", force: :cascade do |t|
    t.integer "advisory_id"
    t.integer "platform_id"
    t.integer "project_id"
    t.index ["advisory_id", "platform_id", "project_id"], name: "unique_platform_project", unique: true
    t.index ["advisory_id"], name: "index_advisory_items_on_advisory_id"
    t.index ["platform_id"], name: "index_advisory_items_on_platform_id"
    t.index ["project_id"], name: "index_advisory_items_on_project_id"
  end

  create_table "arches", force: :cascade do |t|
    t.datetime "created_at"
    t.string "name", limit: 255, null: false
    t.datetime "updated_at"
    t.index ["name"], name: "index_arches_on_name", unique: true
  end

  create_table "build_list_items", force: :cascade do |t|
    t.integer "build_list_id"
    t.datetime "created_at"
    t.integer "level"
    t.string "name", limit: 255
    t.integer "status"
    t.datetime "updated_at"
    t.string "version", limit: 255
    t.index ["build_list_id"], name: "index_build_list_items_on_build_list_id"
  end

  create_table "build_list_packages", force: :cascade do |t|
    t.boolean "actual", default: false
    t.integer "build_list_id"
    t.datetime "created_at", null: false
    t.text "dependent_packages"
    t.integer "epoch"
    t.string "fullname", limit: 255
    t.string "name", limit: 255
    t.string "package_type", limit: 255
    t.integer "platform_id"
    t.integer "project_id"
    t.string "release", limit: 255
    t.string "sha1", limit: 255
    t.bigint "size", default: 0
    t.datetime "updated_at", null: false
    t.string "version", limit: 255
    t.index "lower((name)::text), length((name)::text)", name: "build_list_packages_ordering"
    t.index ["actual"], name: "index_build_list_packages_on_actual_and_platform_id"
    t.index ["build_list_id"], name: "index_build_list_packages_on_build_list_id"
    t.index ["name"], name: "index_build_list_packages_on_name_and_project_id"
    t.index ["platform_id"], name: "index_build_list_packages_on_platform_id"
    t.index ["project_id"], name: "index_build_list_packages_on_project_id"
  end

  create_table "build_lists", force: :cascade do |t|
    t.text "additional_repos"
    t.integer "advisory_id"
    t.integer "arch_id"
    t.boolean "auto_create_container", default: false
    t.string "auto_publish_status", limit: 255, default: "default", null: false
    t.integer "build_for_platform_id"
    t.integer "builder_id"
    t.integer "chain_build_id"
    t.string "commit_hash", limit: 255
    t.integer "container_status"
    t.datetime "created_at"
    t.integer "duration"
    t.string "external_nodes", limit: 255
    t.text "extra_build_lists"
    t.text "extra_params"
    t.text "extra_repositories"
    t.string "fail_reason"
    t.boolean "first_in_chain", default: false
    t.integer "group_id"
    t.string "hostname"
    t.text "include_repos"
    t.boolean "include_testing_subrepository"
    t.boolean "is_circle", default: false
    t.string "last_published_commit_hash", limit: 255
    t.integer "level", default: 0
    t.integer "mass_build_id"
    t.string "name", limit: 255
    t.boolean "new_core", default: true
    t.datetime "notified_at"
    t.string "package_version", limit: 255
    t.integer "priority", default: 0, null: false
    t.integer "project_id"
    t.string "project_version", limit: 255
    t.integer "publisher_id"
    t.text "results"
    t.boolean "save_buildroot", default: false, null: false
    t.integer "save_to_platform_id"
    t.integer "save_to_repository_id"
    t.datetime "started_at"
    t.integer "status"
    t.string "update_type", limit: 255
    t.datetime "updated_at"
    t.boolean "use_cached_chroot", default: false, null: false
    t.boolean "use_extra_tests", default: true, null: false
    t.integer "user_id"
    t.index ["advisory_id"], name: "index_build_lists_on_advisory_id"
    t.index ["arch_id"], name: "index_build_lists_on_arch_id"
    t.index ["chain_build_id"], name: "index_build_lists_on_chain_build_id"
    t.index ["mass_build_id"], name: "index_build_lists_on_mass_build_id_and_status"
    t.index ["project_id", "save_to_repository_id", "build_for_platform_id", "arch_id"], name: "maintainer_search_index"
    t.index ["project_id"], name: "index_build_lists_on_project_id"
    t.index ["updated_at"], name: "index_build_lists_on_updated_at", order: :desc
    t.index ["user_id"], name: "index_build_lists_on_user_id"
  end

  create_table "chain_builds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "platform_id"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["platform_id"], name: "index_chain_builds_on_platform_id"
    t.index ["user_id"], name: "index_chain_builds_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.boolean "automatic", default: false
    t.text "body"
    t.decimal "commentable_id", precision: 50
    t.string "commentable_type", limit: 255
    t.datetime "created_at"
    t.decimal "created_from_commit_hash", precision: 50
    t.integer "created_from_issue_id"
    t.text "data"
    t.integer "project_id"
    t.datetime "updated_at"
    t.integer "user_id"
    t.index ["automatic"], name: "index_comments_on_automatic"
    t.index ["commentable_id"], name: "index_comments_on_commentable_id"
    t.index ["commentable_type"], name: "index_comments_on_commentable_type"
    t.index ["created_from_commit_hash"], name: "index_comments_on_created_from_commit_hash"
    t.index ["created_from_issue_id"], name: "index_comments_on_created_from_issue_id"
  end

  create_table "event_logs", force: :cascade do |t|
    t.string "action", limit: 255
    t.string "controller", limit: 255
    t.datetime "created_at"
    t.integer "eventable_id"
    t.string "eventable_name", limit: 255
    t.string "eventable_type", limit: 255
    t.string "ip", limit: 255
    t.string "kind", limit: 255
    t.text "message"
    t.string "protocol", limit: 255
    t.datetime "updated_at"
    t.integer "user_id"
    t.string "user_name", limit: 255
  end

  create_table "flash_notifies", force: :cascade do |t|
    t.text "body_en", null: false
    t.text "body_ru", null: false
    t.datetime "created_at", null: false
    t.boolean "published", default: true, null: false
    t.string "status", limit: 255, null: false
    t.datetime "updated_at", null: false
  end

  create_table "groups", force: :cascade do |t|
    t.string "avatar_content_type", limit: 255
    t.string "avatar_file_name", limit: 255
    t.integer "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.datetime "created_at"
    t.string "default_branch", limit: 255
    t.text "description"
    t.integer "own_projects_count", default: 0, null: false
    t.integer "owner_id"
    t.string "uname", limit: 255
    t.datetime "updated_at"
  end

  create_table "hooks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.string "name", limit: 255
    t.integer "project_id"
    t.datetime "updated_at", null: false
  end

  create_table "invites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "invite_key", default: ""
    t.integer "invited_user_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["invite_key"], name: "index_invites_on_invite_key"
    t.index ["invited_user_id"], name: "index_invites_on_invited_user_id"
    t.index ["user_id"], name: "index_invites_on_user_id"
  end

  create_table "issues", force: :cascade do |t|
    t.integer "assignee_id"
    t.text "body"
    t.datetime "closed_at"
    t.integer "closed_by"
    t.datetime "created_at"
    t.integer "project_id"
    t.integer "serial_id"
    t.string "status", limit: 255, default: "open"
    t.string "title", limit: 255
    t.datetime "updated_at"
    t.integer "user_id"
    t.index ["project_id"], name: "index_issues_on_project_id_and_serial_id", unique: true
    t.index ["user_id"], name: "index_issues_on_user_id"
  end

  create_table "key_pairs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "encrypted_secret", null: false
    t.string "key_id", limit: 255, null: false
    t.text "public", null: false
    t.integer "repository_id", null: false
    t.text "secret", default: "26809f6e823632ee115928be", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["repository_id"], name: "index_key_pairs_on_repository_id", unique: true
  end

  create_table "labelings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "issue_id"
    t.integer "label_id", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id"], name: "index_labelings_on_issue_id"
  end

  create_table "labels", force: :cascade do |t|
    t.string "color", limit: 255, null: false
    t.datetime "created_at", null: false
    t.string "name", limit: 255, null: false
    t.integer "project_id"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_labels_on_project_id"
  end

  create_table "mass_builds", force: :cascade do |t|
    t.string "arch_names", limit: 255
    t.boolean "auto_create_container", default: false, null: false
    t.string "auto_publish_status", limit: 255, default: "none", null: false
    t.integer "build_for_platform_id", null: false
    t.integer "build_lists_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "description", limit: 255
    t.string "external_nodes", limit: 255
    t.text "extra_build_lists"
    t.text "extra_mass_builds"
    t.text "extra_repositories"
    t.boolean "include_testing_subrepository", default: false, null: false
    t.boolean "increase_release_tag", default: false, null: false
    t.integer "missed_projects_count", default: 0, null: false
    t.text "missed_projects_list"
    t.string "name", limit: 255
    t.boolean "new_core", default: true
    t.text "projects_list"
    t.integer "save_to_platform_id", null: false
    t.integer "status", default: 2000, null: false
    t.boolean "stop_build", default: false, null: false
    t.datetime "updated_at", null: false
    t.boolean "use_cached_chroot", default: true, null: false
    t.boolean "use_extra_tests", default: false, null: false
    t.integer "user_id"
  end

  create_table "platform_arch_settings", force: :cascade do |t|
    t.integer "arch_id", null: false
    t.datetime "created_at", null: false
    t.boolean "default"
    t.integer "platform_id", null: false
    t.integer "time_living", null: false
    t.datetime "updated_at", null: false
    t.index ["platform_id"], name: "index_platform_arch_settings_on_platform_id_and_arch_id", unique: true
  end

  create_table "platforms", force: :cascade do |t|
    t.string "automatic_metadata_regeneration", limit: 255
    t.datetime "created_at"
    t.string "default_branch", limit: 255, null: false
    t.string "description", limit: 255
    t.string "distrib_type", limit: 255, null: false
    t.datetime "last_regenerated_at"
    t.string "last_regenerated_log_sha1", limit: 255
    t.integer "last_regenerated_status"
    t.string "name", limit: 255, null: false
    t.integer "owner_id"
    t.string "owner_type", limit: 255
    t.integer "parent_platform_id"
    t.string "platform_type", limit: 255, default: "main", null: false
    t.boolean "released", default: false, null: false
    t.integer "status"
    t.datetime "updated_at"
    t.string "visibility", limit: 255, default: "open", null: false
    t.index ["name"], name: "index_platforms_on_name", unique: true
  end

  create_table "product_build_lists", force: :cascade do |t|
    t.integer "arch_id"
    t.boolean "autostarted", default: false
    t.string "commit_hash", limit: 255
    t.datetime "created_at"
    t.string "main_script", limit: 255
    t.boolean "not_delete", default: false
    t.text "params"
    t.integer "product_id"
    t.integer "project_id"
    t.string "project_version", limit: 255
    t.text "results"
    t.integer "status", null: false
    t.integer "time_living"
    t.datetime "updated_at"
    t.integer "user_id"
    t.index ["product_id"], name: "index_product_build_lists_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.integer "autostart_status"
    t.datetime "created_at"
    t.text "description"
    t.string "main_script", limit: 255
    t.string "name", limit: 255, null: false
    t.text "params"
    t.integer "platform_id", null: false
    t.integer "project_id"
    t.string "project_version", limit: 255
    t.integer "time_living"
    t.datetime "updated_at"
  end

  create_table "project_imports", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "file_mtime"
    t.string "name", limit: 255
    t.integer "platform_id"
    t.integer "project_id"
    t.datetime "updated_at"
    t.string "version", limit: 255
    t.index ["name"], name: "index_project_imports_on_name_and_platform_id", unique: true
  end

  create_table "project_statistics", force: :cascade do |t|
    t.integer "arch_id", null: false
    t.integer "average_build_time", default: 0, null: false
    t.integer "build_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_statistics_on_project_id_and_arch_id", unique: true
  end

  create_table "project_tags", force: :cascade do |t|
    t.string "commit_id", limit: 255
    t.datetime "created_at", null: false
    t.integer "format_id"
    t.integer "project_id"
    t.string "sha1", limit: 255
    t.string "tag_name", limit: 255
    t.datetime "updated_at", null: false
  end

  create_table "project_to_repositories", force: :cascade do |t|
    t.hstore "autostart_options"
    t.datetime "created_at"
    t.integer "project_id"
    t.integer "repository_id"
    t.datetime "updated_at"
    t.index ["repository_id"], name: "index_project_to_repositories_on_repository_id_and_project_id", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.integer "alias_from_id"
    t.string "ancestry", limit: 255
    t.boolean "architecture_dependent", default: false, null: false
    t.integer "autostart_status"
    t.datetime "created_at"
    t.string "default_branch", limit: 255, default: "master"
    t.text "description"
    t.boolean "has_issues", default: true
    t.boolean "is_package", default: true, null: false
    t.integer "maintainer_id"
    t.string "name", limit: 255
    t.integer "owner_id"
    t.string "owner_type", limit: 255
    t.string "owner_uname", limit: 255, null: false
    t.boolean "publish_i686_into_x86_64", default: false
    t.string "srpm_content_type", limit: 255
    t.string "srpm_file_name", limit: 255
    t.integer "srpm_file_size"
    t.datetime "srpm_updated_at"
    t.datetime "updated_at"
    t.string "visibility", limit: 255, default: "open"
    t.index ["alias_from_id"], name: "index_projects_on_alias_from_id"
    t.index ["name"], name: "index_projects_on_name_and_owner_id_and_owner_type", unique: true
  end

  create_table "pull_requests", force: :cascade do |t|
    t.integer "from_project_id", null: false
    t.string "from_project_name", limit: 255
    t.string "from_project_owner_uname", limit: 255
    t.string "from_ref", limit: 255, null: false
    t.integer "issue_id", null: false
    t.integer "to_project_id", null: false
    t.string "to_ref", limit: 255, null: false
    t.index ["from_project_id"], name: "index_pull_requests_on_head_project_id"
    t.index ["issue_id"], name: "index_pull_requests_on_issue_id"
    t.index ["to_project_id"], name: "index_pull_requests_on_base_project_id"
  end

  create_table "relations", force: :cascade do |t|
    t.integer "actor_id"
    t.string "actor_type", limit: 255
    t.datetime "created_at"
    t.string "role", limit: 255
    t.integer "target_id"
    t.string "target_type", limit: 255
    t.datetime "updated_at"
    t.index ["actor_type"], name: "index_relations_on_actor_type_and_actor_id"
    t.index ["target_type"], name: "index_relations_on_target_type_and_target_id"
  end

  create_table "repositories", force: :cascade do |t|
    t.datetime "created_at"
    t.string "description", limit: 255, null: false
    t.string "name", limit: 255, null: false
    t.integer "platform_id", null: false
    t.string "publish_builds_only_from_branch", limit: 255
    t.boolean "publish_without_qa", default: true
    t.boolean "synchronizing_publications", default: false, null: false
    t.datetime "updated_at"
    t.index ["platform_id"], name: "index_repositories_on_platform_id"
  end

  create_table "repository_statuses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_regenerated_at"
    t.string "last_regenerated_log_sha1", limit: 255
    t.integer "last_regenerated_status"
    t.integer "platform_id", null: false
    t.integer "repository_id", null: false
    t.boolean "resign_rpms", default: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["repository_id"], name: "index_repository_statuses_on_repository_id_and_platform_id", unique: true
  end

  create_table "settings_notifiers", force: :cascade do |t|
    t.boolean "can_notify", default: true
    t.datetime "created_at"
    t.boolean "issue_assign", default: true
    t.boolean "new_associated_build", default: true
    t.boolean "new_build", default: true
    t.boolean "new_comment", default: true
    t.boolean "new_comment_commit_commentor", default: true
    t.boolean "new_comment_commit_owner", default: true
    t.boolean "new_comment_commit_repo_owner", default: true
    t.boolean "new_comment_reply", default: true
    t.boolean "new_issue", default: true
    t.boolean "update_code", default: false
    t.datetime "updated_at"
    t.integer "user_id", null: false
  end

  create_table "ssh_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "fingerprint", limit: 255, null: false
    t.text "key", null: false
    t.string "name", limit: 255
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["fingerprint"], name: "index_ssh_keys_on_fingerprint", unique: true
    t.index ["user_id"], name: "index_ssh_keys_on_user_id"
  end

  create_table "statistics", force: :cascade do |t|
    t.datetime "activity_at", null: false
    t.integer "counter", default: 0, null: false
    t.datetime "created_at"
    t.string "email", limit: 255, null: false
    t.string "key", limit: 255, null: false
    t.integer "project_id", null: false
    t.string "project_name_with_owner", limit: 255, null: false
    t.datetime "updated_at"
    t.integer "user_id", null: false
    t.index ["activity_at"], name: "index_statistics_on_activity_at"
    t.index ["key", "activity_at"], name: "index_statistics_on_key_and_activity_at"
    t.index ["key"], name: "index_statistics_on_key"
    t.index ["project_id", "key", "activity_at"], name: "index_statistics_on_project_id_and_key_and_activity_at"
    t.index ["project_id"], name: "index_statistics_on_project_id"
    t.index ["user_id", "key", "activity_at"], name: "index_statistics_on_user_id_and_key_and_activity_at"
    t.index ["user_id", "project_id", "key", "activity_at"], name: "index_statistics_on_all_keys", unique: true
    t.index ["user_id"], name: "index_statistics_on_user_id"
  end

  create_table "subscribes", force: :cascade do |t|
    t.datetime "created_at"
    t.integer "project_id"
    t.boolean "status", default: true
    t.decimal "subscribeable_id", precision: 50
    t.string "subscribeable_type", limit: 255
    t.datetime "updated_at"
    t.integer "user_id"
  end

  create_table "tokens", force: :cascade do |t|
    t.string "authentication_token", limit: 255, null: false
    t.datetime "created_at", null: false
    t.integer "creator_id", null: false
    t.text "description"
    t.string "status", limit: 255, default: "active"
    t.integer "subject_id", null: false
    t.string "subject_type", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.integer "updater_id"
    t.index ["authentication_token"], name: "index_tokens_on_authentication_token", unique: true
    t.index ["subject_id"], name: "index_tokens_on_subject_id_and_subject_type"
  end

  create_table "user_builds_settings", force: :cascade do |t|
    t.string "external_nodes", limit: 255
    t.text "platforms", default: [], null: false, array: true
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_user_builds_settings_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "access_to_advisories_api", default: false
    t.boolean "access_to_token_api", default: false
    t.string "authentication_token", limit: 255
    t.string "avatar_content_type", limit: 255
    t.string "avatar_file_name", limit: 255
    t.integer "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer "build_priority", default: 50
    t.string "company", limit: 255
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at"
    t.datetime "created_at"
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 128, default: "", null: false
    t.integer "failed_attempts", default: 0
    t.boolean "hide_email", default: true, null: false
    t.string "language", limit: 255, default: "en"
    t.string "location", limit: 255
    t.datetime "locked_at"
    t.string "name", limit: 255
    t.integer "own_projects_count", default: 0, null: false
    t.text "professional_experience"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token", limit: 255
    t.string "role", limit: 255
    t.string "site", limit: 255
    t.boolean "sound_notifications", default: true
    t.text "ssh_key"
    t.string "uname", limit: 255
    t.string "unlock_token", limit: 255
    t.datetime "updated_at"
    t.index ["authentication_token"], name: "index_users_on_authentication_token"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uname"], name: "index_users_on_uname", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "advisory_items", "advisories", name: "fk_advisory_items_advisory_id"
  add_foreign_key "advisory_items", "platforms", name: "fk_advisory_items_platform_id"
  add_foreign_key "build_lists", "chain_builds", name: "fk_build_lists_chain_build_id"
  add_foreign_key "chain_builds", "platforms", name: "fk_chain_builds_platform_id"
  add_foreign_key "chain_builds", "users", name: "fk_chain_builds_user_id"
  add_foreign_key "invites", "users", name: "fk_invites_user_id"
end
