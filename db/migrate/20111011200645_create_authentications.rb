class CreateAuthentications < ActiveRecord::Migration
  def self.up
    create_table :authentications do |t|
      t.references :user
      t.string :provider
      t.string :uid

      t.timestamps
    end

    add_index :authentications, :user_id
    add_index :authentications, [:provider, :uid], unique: true
  end

  def self.down
    drop_table :authentications
  end
end
