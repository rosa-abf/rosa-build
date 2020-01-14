class AddResignRpmsToRepositoryStatus < ActiveRecord::Migration
  def change
    add_column :repository_statuses, :resign_rpms, :bool, default: false
  end
end
