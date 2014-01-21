class AddBuildPriorityToUsers < ActiveRecord::Migration
  def up
    add_column :users, :build_priority, :integer, default: 50
    User.update_all build_priority: 50
  end

  def down
    remove_column :users, :build_priority
  end

end
