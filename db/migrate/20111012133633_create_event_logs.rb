class CreateEventLogs < ActiveRecord::Migration
  def self.up
    create_table :event_logs do |t|
      t.references :user, foreign_key: false, index: true
      t.string :user_name
      t.references :object, polymorphic: true, index: true
      t.string :object_name
      t.string :ip
      t.string :kind
      t.string :protocol
      t.string :controller
      t.string :action
      t.text :message

      t.timestamps
    end
  end

  def self.down
    drop_table :event_logs
  end
end
