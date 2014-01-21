class DisableNullValueForKeyPairs < ActiveRecord::Migration
  def up
  	change_column_null :key_pairs, :repository_id,  false
  	change_column_null :key_pairs, :user_id,  		false
  	change_column_null :key_pairs, :key_id, 		false
  	change_column_null :key_pairs, :public, 		false
  	add_index          :key_pairs, :repository_id, unique: true
  end

  def down
  	change_column_null :key_pairs, :repository_id,  true
  	change_column_null :key_pairs, :user_id,  		true
  	change_column_null :key_pairs, :key_id, 		true
  	change_column_null :key_pairs, :public, 		true
  	remove_index 	   :key_pairs, :repository_id
  end
end
