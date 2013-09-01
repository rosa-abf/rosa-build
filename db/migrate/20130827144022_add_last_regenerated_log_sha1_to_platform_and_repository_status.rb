class AddLastRegeneratedLogSha1ToPlatformAndRepositoryStatus < ActiveRecord::Migration
  def change
    add_column :platforms, :last_regenerated_log_sha1, :string
    add_column :repository_statuses, :last_regenerated_log_sha1, :string
  end
end
