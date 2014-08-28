class CreateAdvisories < ActiveRecord::Migration
  def change
    create_table :advisories do |t|
      t.string  :advisory_id, references: nil
      t.integer :project_id, references: nil
      t.text    :description, default: ''
      t.text    :references,  default: ''
      t.text    :update_type, default: ''

      t.timestamps
    end
    add_index :advisories, :advisory_id, unique: true
    add_index :advisories, :project_id
    add_index :advisories, :update_type
  end
end
