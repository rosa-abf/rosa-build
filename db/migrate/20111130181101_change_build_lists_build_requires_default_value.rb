class ChangeBuildListsBuildRequiresDefaultValue < ActiveRecord::Migration
  def self.up
    change_column_default :build_lists, :build_requires, false
  end

  def self.down
    change_column_default :build_lists, :build_requires, nil
  end
end
