class SetDefaultValueForNewCore < ActiveRecord::Migration[8.1]
  def up
    change_column :build_lists, :new_core, :boolean, default: true
  end

  def down
    change_column :build_lists, :new_core, :boolean, default: nil
  end
end
