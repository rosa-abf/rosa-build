# -*- encoding : utf-8 -*-
class AddDefaultValuesToIsRpmForProjects < ActiveRecord::Migration
  def change
    Project.update_all(:is_rpm => true)
  end
end
