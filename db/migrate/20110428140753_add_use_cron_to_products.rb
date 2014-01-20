class AddUseCronToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :use_cron, :boolean, :default => false
  end

  def self.down
    remove_column :products, :use_cron
  end
end
