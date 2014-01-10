class AddIndexToRelation < ActiveRecord::Migration
  def change
    add_index :relations, [:actor_type, :actor_id]
    add_index :relations, [:target_type, :target_id]
  end
end
