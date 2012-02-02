class AddProjectToSubscribe < ActiveRecord::Migration
  def self.up
    add_column :subscribes, :project_id, :integer
  end

  def self.down
    remove_column :subscribes, :project_id
  end
end
