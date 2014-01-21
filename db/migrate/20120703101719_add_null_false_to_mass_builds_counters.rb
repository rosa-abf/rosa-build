class AddNullFalseToMassBuildsCounters < ActiveRecord::Migration
  def change
    change_column :mass_builds, :build_lists_count, :integer, default: 0, null: false
    change_column :mass_builds, :build_published_count, :integer, default: 0, null: false
    change_column :mass_builds, :build_pending_count, :integer, default: 0, null: false
    change_column :mass_builds, :build_started_count, :integer, default: 0, null: false
    change_column :mass_builds, :build_publish_count, :integer, default: 0, null: false
    change_column :mass_builds, :build_error_count, :integer, default: 0, null: false
  end
end
