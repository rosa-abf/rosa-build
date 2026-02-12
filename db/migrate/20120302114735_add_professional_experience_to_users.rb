class AddProfessionalExperienceToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :professional_experience, :text
  end
end
