class SetMassBuildUserIdToFirstIfNil < ActiveRecord::Migration
  def up
    MassBuild.update_all(user_id: nil, user_id: 1)
  end

  def down
  end
end
