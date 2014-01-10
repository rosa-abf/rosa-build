class AddUseTestingRepoToBuildList < ActiveRecord::Migration
  def change
    add_column :build_lists, :include_testing_subrepository, :boolean
  end
end
