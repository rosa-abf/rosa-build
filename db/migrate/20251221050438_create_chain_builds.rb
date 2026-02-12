class CreateChainBuilds < ActiveRecord::Migration[8.1]
  def change
    create_table :chain_builds do |t|
      t.references :user, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
