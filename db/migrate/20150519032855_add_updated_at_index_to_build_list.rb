class AddUpdatedAtIndexToBuildList < ActiveRecord::Migration
  def change
    add_index :build_lists, :updated_at, order: { updated_at: :desc }
  end
end
