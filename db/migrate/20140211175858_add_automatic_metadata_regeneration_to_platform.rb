class AddAutomaticMetadataRegenerationToPlatform < ActiveRecord::Migration[8.1]
  def change
    add_column :platforms, :automatic_metadata_regeneration, :string
  end
end
