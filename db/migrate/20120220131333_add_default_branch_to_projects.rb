class AddDefaultBranchToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :default_branch, :string, :default => 'master'

  end
end
