class AddStatusToPlatform < ActiveRecord::Migration
  def change
    add_column :platforms, :status, :integer
    add_column :platforms, :last_regenerated_at, :datetime
    add_column :platforms, :last_regenerated_status, :integer
  end
end
