class ChangeObjectToEventableInEventLog < ActiveRecord::Migration
  def up
    change_table :event_logs do |t|
      t.rename :object_id,   :eventable_id
      t.rename :object_type, :eventable_type
      t.rename :object_name, :eventable_name
    end
  end

  def down
    change_table :event_logs do |t|
      t.rename :eventable_id,   :object_id
      t.rename :eventable_type, :object_type
      t.rename :eventable_name, :object_name
    end
  end
end
