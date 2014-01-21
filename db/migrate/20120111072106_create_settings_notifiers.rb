class CreateSettingsNotifiers < ActiveRecord::Migration
  def self.up
    create_table :settings_notifiers do |t|
      t.integer :user_id, null: false

      t.boolean :can_notify, default: true
      t.boolean :new_comment, default: true
      t.boolean :new_comment_reply, default: true
      t.boolean :new_issue, default: true
      t.boolean :issue_assign, default: true

      t.timestamps
    end
  end

  def self.down
    drop_table :settings_notifiers
  end
end
