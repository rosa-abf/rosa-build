class AddManyProjectsToAdvisories < ActiveRecord::Migration
  def up
    create_table :advisories_projects, id: false do |t|
      t.integer :advisory_id
      t.integer :project_id
    end
    add_index :advisories_projects, :advisory_id
    add_index :advisories_projects, :project_id
    add_index :advisories_projects, [:advisory_id, :project_id], name: :advisory_project_index, unique: true

    Advisory.find_in_batches do |b|
      b.each do |advisory|
        advisory.projects << Project.find(advisory.project_id)
        advisory.save
      end
    end

    change_table :advisories do |t|
      t.remove :project_id
    end
  end

  def down
    change_table :advisories do |t|
      t.integer :project_id
    end

    Advisory.find_in_batches do |b|
      b.each do |advisory|
        advisory.project_id = advisory.projects.first.id
        advisory.save
      end
    end

    remove_index :advisories_projects, column: :advisory_id
    remove_index :advisories_projects, column: :project_id
    remove_index :advisories_projects, name: :advisory_project_index
    drop_table   :advisories_projects
  end
end
