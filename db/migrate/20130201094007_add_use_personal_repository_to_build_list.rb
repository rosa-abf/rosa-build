class AddUsePersonalRepositoryToBuildList < ActiveRecord::Migration[8.1]
  def change
    add_column :build_lists, :use_save_to_repository, :boolean, default: true
  end
end
