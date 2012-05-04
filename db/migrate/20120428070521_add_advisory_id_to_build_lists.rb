class AddAdvisoryIdToBuildLists < ActiveRecord::Migration
  def change
    add_column :build_lists, :advisory_id, :integer
    add_index  :build_lists, :advisory_id

  end
end
