class AddSynchronizePublicationToRepository < ActiveRecord::Migration
  def change
    add_column :repositories, :synchronizing_publications, :boolean, :default => false, :null => false
  end
end
