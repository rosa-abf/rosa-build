class AddSaveBuildrootToBuildLists < ActiveRecord::Migration
  def change
    add_column :build_lists, :save_buildroot, :boolean, default: false, null: false
  end
end
