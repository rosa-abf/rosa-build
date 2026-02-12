class AddForbidToPublishBuildsNotFromToRepositories < ActiveRecord::Migration[8.1]
  def change
    add_column :repositories, :forbid_to_publish_builds_not_from, :boolean, null: false, default: true
  end
end
