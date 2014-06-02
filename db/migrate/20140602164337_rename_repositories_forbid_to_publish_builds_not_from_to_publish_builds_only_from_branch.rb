class RenameRepositoriesForbidToPublishBuildsNotFromToPublishBuildsOnlyFromBranch < ActiveRecord::Migration
  def change
    change_table :repositories do |t|
      t.rename :forbid_to_publish_builds_not_from, :publish_builds_only_from_branch
    end
  end
end
