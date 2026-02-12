class AddChainBuildToBuildLists < ActiveRecord::Migration[8.1]
  def change
    add_reference :build_lists, :chain_build, index: true, null: true, foreign_key: true
  end
end
