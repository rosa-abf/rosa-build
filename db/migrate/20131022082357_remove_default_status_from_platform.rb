class RemoveDefaultStatusFromPlatform < ActiveRecord::Migration
  def change
    change_column :platforms, :status, :integer, default: nil
  end
end
