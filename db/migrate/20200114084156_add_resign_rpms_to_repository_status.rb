class AddResignRpmsToRepositoryStatus < ActiveRecord::Migration[8.1]
  def change
    add_column :repository_statuses, :resign_rpms, :bool, default: false
  end
end
