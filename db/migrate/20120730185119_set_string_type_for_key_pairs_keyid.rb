class SetStringTypeForKeyPairsKeyid < ActiveRecord::Migration[8.1]
  def up
  	change_column :key_pairs, :key_id, :string #, references: nil
  end

  def down
  	change_column :key_pairs, :key_id, :integer
  end
end
