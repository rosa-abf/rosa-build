class AddStatusToPlatform < ActiveRecord::Migration[8.1]
  def change
    add_column :platforms, :status, :integer, default: 0
    add_column :platforms, :last_regenerated_at, :datetime
    add_column :platforms, :last_regenerated_status, :integer
  end
end
