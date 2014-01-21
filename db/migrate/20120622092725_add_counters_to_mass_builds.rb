class AddCountersToMassBuilds < ActiveRecord::Migration
  def change
    add_column :mass_builds, :build_lists_count, :integer, default: 0
    add_column :mass_builds, :build_published_count, :integer, default: 0
    add_column :mass_builds, :build_pending_count, :integer, default: 0
    add_column :mass_builds, :build_started_count, :integer, default: 0
    add_column :mass_builds, :build_publish_count, :integer, default: 0
    add_column :mass_builds, :build_error_count, :integer, default: 0
  end
end
