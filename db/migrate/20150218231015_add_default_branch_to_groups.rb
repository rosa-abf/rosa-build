class AddDefaultBranchToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :default_branch, :string
  end
end
