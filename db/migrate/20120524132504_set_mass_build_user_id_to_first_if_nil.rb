class SetMassBuildUserIdToFirstIfNil < ActiveRecord::Migration[8.1]
  def up
    MassBuild.update_all(user_id: nil, user_id: 1)
  end

  def down
  end
end
