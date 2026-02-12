class AddEncryptedSecretIvToKeyPairs < ActiveRecord::Migration[8.1]
  def change
    add_column :key_pairs, :secret, :text, null: false, default: SecureRandom.hex(12)
#    add_index :key_pairs, :secret, unique: true, if_not_exists: true
  end
end

