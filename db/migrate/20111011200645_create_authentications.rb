class CreateAuthentications < ActiveRecord::Migration[8.1]
  def self.up
    create_table :authentications do |t|
      t.references :user
      t.string :provider
      t.string :uid

      t.timestamps
    end

    add_index :authentications, :user_id, if_not_exists: true
    add_index :authentications, [:provider, :uid], unique: true, if_not_exists: true
  end

  def self.down
    drop_table :authentications
  end
end
