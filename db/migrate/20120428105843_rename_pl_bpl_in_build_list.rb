class RenamePlBplInBuildList < ActiveRecord::Migration
  def up
    change_table :build_lists do |t|
      t.rename :pl_id,  :save_to_platform_id
      t.rename :bpl_id, :build_for_platform_id
    end
  end

  def down
    change_table :build_lists do |t|
      t.rename :save_to_platform_id,   :pl_id
      t.rename :build_for_platform_id, :bpl_id
    end
  end
end
