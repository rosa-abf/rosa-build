class RemoveDefaultStatusFromPlatform < ActiveRecord::Migration[8.1]
  def change
    change_column :platforms, :status, :integer, default: nil
  end
end
