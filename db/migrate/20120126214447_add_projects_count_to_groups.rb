class AddProjectsCountToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :own_projects_count, :integer, :default => 0, :null => false

    Group.reset_column_information
    Group.all.each do |group|
      Group.reset_counters(group.id, :own_projects)
    end
  end

  def self.down
    remove_column :groups, :own_projects_count
  end
end
