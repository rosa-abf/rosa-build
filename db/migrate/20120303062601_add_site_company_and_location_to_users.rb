class AddSiteCompanyAndLocationToUsers < ActiveRecord::Migration
  def change
    add_column :users, :site, :string
    add_column :users, :company, :string
    add_column :users, :location, :string
  end
end
