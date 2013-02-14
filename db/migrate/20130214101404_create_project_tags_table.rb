class CreateProjectTagsTable < ActiveRecord::Migration
  def change
    create_table :project_tags do |t|
      t.integer :project_id
      t.string  :commit_id
      t.string  :sha1
      t.string  :tag_name
      t.integer :format_id
      t.timestamps
    end
  end
end
