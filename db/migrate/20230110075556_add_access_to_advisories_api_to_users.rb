class AddAccessToAdvisoriesApiToUsers < ActiveRecord::Migration
  def change
    add_column :users, :access_to_advisories_api, :bool, default: false
  end
end
