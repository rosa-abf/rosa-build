class CustomizePlatform < ActiveRecord::Migration
  def self.up
    change_column_null :platforms, :name, false
    #change_column_null :platforms, :distrib_type, false
    change_column_null :platforms, :platform_type, false
    change_column_null :platforms, :released, false
    change_column_null :platforms, :visibility, false
    add_index "platforms", ["name"], unique: true, case_sensitive: false
  end

  def self.down
    change_column_null :platforms, :name, true
    change_column_null :platforms, :distrib_type, true
    change_column_null :platforms, :platform_type, true
    change_column_null :platforms, :released,  true
    change_column_null :platforms, :visibility, true
    remove_index "platforms", ["name"]
  end
end
