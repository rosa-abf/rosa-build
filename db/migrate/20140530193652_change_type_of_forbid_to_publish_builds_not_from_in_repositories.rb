class ChangeTypeOfForbidToPublishBuildsNotFromInRepositories < ActiveRecord::Migration
  def up
    remove_column :repositories, :forbid_to_publish_builds_not_from
    add_column    :repositories, :forbid_to_publish_builds_not_from, :string
    execute <<-SQL
      UPDATE repositories SET forbid_to_publish_builds_not_from = platforms.name
        FROM platforms
        WHERE repositories.platform_id = platforms.id
    SQL
  end

  def down
    remove_column :repositories, :forbid_to_publish_builds_not_from
    add_column    :repositories, :forbid_to_publish_builds_not_from, :boolean, null: false, default: true
  end
end
