class AddSaveBuildrootToBuildLists < ActiveRecord::Migration[8.1]
  def change
    add_column :build_lists, :save_buildroot, :boolean, default: false, null: false
  end
end
