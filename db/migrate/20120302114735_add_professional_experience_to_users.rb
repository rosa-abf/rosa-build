class AddProfessionalExperienceToUsers < ActiveRecord::Migration
  def change
    add_column :users, :professional_experience, :text
  end
end
