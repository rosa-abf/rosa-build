class CreateAdvisoryItems < ActiveRecord::Migration
  def change
    create_table :advisory_items do |t|
      t.references :advisory, index: true, foreign_key: true
      t.references :platform, index: true, foreign_key: true
      t.references :project, index: true, foreign_key: true

      t.index [:advisory_id, :platform_id, :project_id], unique: true, name: 'unique_platform_project'
    end
  end
end
