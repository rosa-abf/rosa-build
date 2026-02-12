class AddSynchronizePublicationToRepository < ActiveRecord::Migration[8.1]
  def change
    add_column :repositories, :synchronizing_publications, :boolean, default: false, null: false
  end
end
