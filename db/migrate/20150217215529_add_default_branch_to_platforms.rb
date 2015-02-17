class AddDefaultBranchToPlatforms < ActiveRecord::Migration
  def up
    add_column :platforms, :default_branch, :string
    execute "UPDATE platforms SET default_branch = name"
    change_column_null :platforms, :default_branch, false
  end

  def down
    remove_column :platforms, :default_branch
  end
end
