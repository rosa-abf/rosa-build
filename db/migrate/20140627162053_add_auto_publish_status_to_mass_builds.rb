class AddAutoPublishStatusToMassBuilds < ActiveRecord::Migration
  class MassBuild < ActiveRecord::Base
  end

  def up
    add_column :mass_builds, :auto_publish_status, :string, default: 'none', null: false
    MassBuild.where(auto_publish: true).update_all(auto_publish_status: :default)
    remove_column :mass_builds, :auto_publish
  end

  def down
    add_column :mass_builds, :auto_publish, :boolean, default: false
    MassBuild.where(auto_publish_status: :default).update_all(auto_publish: true)
    remove_column :mass_builds, :auto_publish_status
  end
end
