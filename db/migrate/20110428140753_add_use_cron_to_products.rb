class AddUseCronToProducts < ActiveRecord::Migration[8.1]
  def self.up
    add_column :products, :use_cron, :boolean, default: false
  end

  def self.down
    remove_column :products, :use_cron
  end
end
