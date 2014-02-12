class AddAutomaticMetadataRegenerationToPlatform < ActiveRecord::Migration
  def change
    add_column :platforms, :automatic_metadata_regeneration, :string
  end
end
