class AddProjectsCountToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :own_projects_count, :integer, :default => 0, :null => false

    User.reset_column_information
    User.all.each do |user|
      User.reset_counters(user.id, :own_projects)
    end
  end

  def self.down
    remove_column :users, :own_projects_count
  end
end
