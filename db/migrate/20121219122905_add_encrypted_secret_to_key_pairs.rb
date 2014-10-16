class AddEncryptedSecretToKeyPairs < ActiveRecord::Migration
  def up
    rename_table :key_pairs, :key_pairs_backup
    # rename_index :key_pairs_backup, 'index_key_pairs_on_repository_id', 'index_key_pairs_backup_on_repository_id'

    create_table :key_pairs do |t|
      t.text :public, null: false
      t.text :encrypted_secret, null: false
      t.string :key_id, null: false, references: nil
      t.references :user, null: false
      t.references :repository, null: false
      t.timestamps
    end
    add_index :key_pairs, :repository_id, unique: true
  end

  def down
    drop_table :key_pairs
    rename_table :key_pairs_backup, :key_pairs
    # rename_index :key_pairs, 'index_key_pairs_backup_on_repository_id', 'index_key_pairs_on_repository_id'
  end
end
