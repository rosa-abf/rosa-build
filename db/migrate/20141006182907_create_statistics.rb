class CreateStatistics < ActiveRecord::Migration
  def up
    create_table :statistics do |t|
      t.integer :user_id,                 null: false
      t.string :email,                    null: false
      t.integer :project_id,              null: false
      t.string :project_name_with_owner,  null: false
      t.string :type,                     null: false
      t.integer :counter,                 null: false, default: 0
      t.datetime :activity_at,            null: false

      t.timestamps
    end


    add_index :statistics, :user_id,                            algorithm: :concurrently
    add_index :statistics, :project_id,                         algorithm: :concurrently
    add_index :statistics, :type,                               algorithm: :concurrently
    add_index :statistics, [:user_id, :type, :activity_at],     algorithm: :concurrently
    add_index :statistics, [:project_id, :type, :activity_at],  algorithm: :concurrently
    add_index :statistics, [:type, :activity_at],               algorithm: :concurrently
    add_index :statistics, :activity_at,                        algorithm: :concurrently

    add_index :statistics, [:user_id, :project_id, :type, :activity_at], unique: true,
      name: 'index_statistics_on_all_keys'
  end

  def down
    drop_table :statistics
  end

end
