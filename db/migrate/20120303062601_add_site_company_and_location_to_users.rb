class AddSiteCompanyAndLocationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :site, :string
    add_column :users, :company, :string
    add_column :users, :location, :string
  end
end
