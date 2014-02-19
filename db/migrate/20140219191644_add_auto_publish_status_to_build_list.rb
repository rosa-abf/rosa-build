class AddAutoPublishStatusToBuildList < ActiveRecord::Migration

  class BuildList < ActiveRecord::Base
  end

  def up
    # Make existing build_lists 'none', but default to 'default' in the future.
    add_column :build_lists, :auto_publish_status, :string, default: 'none', null: false
    BuildList.where(auto_publish: true).update_all(auto_publish_status: :default)
    change_column :build_lists, :auto_publish_status, :string, default: 'default', null: false
  end

  def down
    remove_column :build_lists, :auto_publish_status
  end
end
