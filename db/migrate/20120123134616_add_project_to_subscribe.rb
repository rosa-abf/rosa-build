class AddProjectToSubscribe < ActiveRecord::Migration[8.1]
  def self.up
    add_column :subscribes, :project_id, :integer
  end

  def self.down
    remove_column :subscribes, :project_id
  end
end
