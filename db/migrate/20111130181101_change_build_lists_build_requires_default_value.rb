class ChangeBuildListsBuildRequiresDefaultValue < ActiveRecord::Migration[8.1]
  def self.up
    change_column_default :build_lists, :build_requires, false
  end

  def self.down
    change_column_default :build_lists, :build_requires, nil
  end
end
