class AddDefaultBranchToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :default_branch, :string, default: 'master'

  end
end
