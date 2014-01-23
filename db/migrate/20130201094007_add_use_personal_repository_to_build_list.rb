class AddUsePersonalRepositoryToBuildList < ActiveRecord::Migration
  def change
    add_column :build_lists, :use_save_to_repository, :boolean, default: true
  end
end
