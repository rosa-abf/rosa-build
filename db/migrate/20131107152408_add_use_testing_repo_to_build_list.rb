class AddUseTestingRepoToBuildList < ActiveRecord::Migration[8.1]
  def change
    add_column :build_lists, :include_testing_subrepository, :boolean
  end
end
