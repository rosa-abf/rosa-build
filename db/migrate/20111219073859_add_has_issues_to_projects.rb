class AddHasIssuesToProjects < ActiveRecord::Migration[8.1]
  def self.up
    add_column :projects, :has_issues, :boolean, default: true
  end

  def self.down
    remove_column :projects, :has_issues
  end
end
