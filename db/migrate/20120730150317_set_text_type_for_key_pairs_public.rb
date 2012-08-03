class SetTextTypeForKeyPairsPublic < ActiveRecord::Migration
  def up
    change_column :key_pairs, :public, :text
  end

  def down
    change_column :key_pairs, :public, :string
  end
end
