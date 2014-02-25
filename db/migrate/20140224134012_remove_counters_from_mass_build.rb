class RemoveCountersFromMassBuild < ActiveRecord::Migration
  def up
    remove_columns :mass_builds, :build_published_count,
                                 :build_pending_count,
                                 :build_started_count,
                                 :build_publish_count,
                                 :build_error_count,
                                 :success_count,
                                 :build_canceled_count
  end

  def down
    add_column :mass_builds, :build_published_count, :integer, default: 0
    add_column :mass_builds, :build_pending_count, :integer, default: 0
    add_column :mass_builds, :build_started_count, :integer, default: 0
    add_column :mass_builds, :build_publish_count, :integer, default: 0
    add_column :mass_builds, :build_error_count, :integer, default: 0
    add_column :mass_builds, :success_count, :integer, default: 0
    add_column :mass_builds, :build_canceled_count, :integer, default: 0
  end
end
