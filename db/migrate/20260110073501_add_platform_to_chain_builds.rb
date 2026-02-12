class AddPlatformToChainBuilds < ActiveRecord::Migration[8.1]
  def change
    add_reference :chain_builds, :platform, index: true, foreign_key: true
  end
end
