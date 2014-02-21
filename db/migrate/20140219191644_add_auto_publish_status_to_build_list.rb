class AddAutoPublishStatusToBuildList < ActiveRecord::Migration

  class BuildList < ActiveRecord::Base
  end

  def up
    # Make existing build_lists 'none', but default to 'default' in the future.
    add_column :build_lists, :auto_publish_status, :string, default: 'none', null: false
    BuildList.where(auto_publish: true).update_all(auto_publish_status: :default)
    change_column :build_lists, :auto_publish_status, :string, default: 'default', null: false
    remove_column :build_lists, :auto_publish
  end

  def down
    # Make existing build_lists false, but default to true in the future.
    add_column :build_lists, :auto_publish, :boolean, default: false
    BuildList.where(auto_publish_status: :default).update_all(auto_publish: true)
    change_column :build_lists, :auto_publish, :boolean, default: true
    remove_column :build_lists, :auto_publish_status
  end
end
