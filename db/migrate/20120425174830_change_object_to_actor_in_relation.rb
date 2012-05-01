class ChangeObjectToActorInRelation < ActiveRecord::Migration
  def up
    change_table :relations do |t|
      t.rename :object_id, :actor_id
      t.rename :object_type, :actor_type
    end
  end

  def down
    change_table :relations do |t|
      t.rename :actor_id, :object_id
      t.rename :actor_type, :object_type
    end
  end
end
