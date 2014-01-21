class AddExtraRepositoriesAndContainersToBuildList < ActiveRecord::Migration
  def change
    add_column :build_lists, :auto_create_container, :boolean, default: false
    add_column :build_lists, :extra_repositories, :text
    add_column :build_lists, :extra_containers,   :text
  end
end
