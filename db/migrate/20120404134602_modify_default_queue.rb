class ModifyDefaultQueue < ActiveRecord::Migration[8.1]
  def up
    change_column :delayed_jobs, :queue, :string, default: 'default'
    execute "UPDATE delayed_jobs SET queue = 'default'"
  end

  def down
    change_column :delayed_jobs, :queue, :string, default: nil
    execute "UPDATE delayed_jobs SET queue = null"
  end
end
