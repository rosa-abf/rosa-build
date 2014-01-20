class CreateSubscribes < ActiveRecord::Migration
  def self.up
    create_table :subscribes do |t|
      t.integer :subscribeable_id
      t.string :subscribeable_type
      t.integer :user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :subscribes
  end
end
