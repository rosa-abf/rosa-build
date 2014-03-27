class CreateKeyPairs < ActiveRecord::Migration
  def change
    create_table :key_pairs do |t|
      t.integer :repository_id
      t.integer :user_id
      t.integer :key_id, references: nil
      t.string  :public
      t.timestamps
    end
  end
end
