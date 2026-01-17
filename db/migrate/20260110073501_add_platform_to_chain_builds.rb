class AddPlatformToChainBuilds < ActiveRecord::Migration
  def change
    add_reference :chain_builds, :platform, index: true, foreign_key: true
  end
end
