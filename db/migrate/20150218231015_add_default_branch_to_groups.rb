class AddDefaultBranchToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :default_branch, :string
  end
end
