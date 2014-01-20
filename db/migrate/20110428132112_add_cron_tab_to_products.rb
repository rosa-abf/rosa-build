class AddCronTabToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :cron_tab, :text
  end

  def self.down
    remove_column :products, :cron_tab
  end
end
