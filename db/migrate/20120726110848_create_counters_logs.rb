class CreateCountersLogs < ActiveRecord::Migration
  def change
    create_table :counters_logs do |t|
      t.integer :mass_build_id
      t.integer :build_list_id
      t.string  :status
      t.string  :event
      t.timestamps
    end
  end
end
