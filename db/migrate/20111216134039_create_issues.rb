class CreateIssues < ActiveRecord::Migration
  def self.up
    create_table :issues do |t|
      t.integer :serial_id, references: nil
      t.integer :project_id
      t.integer :user_id
      t.string :title
      t.text :body
      t.string :status

      t.timestamps
    end

    add_index :issues, [:project_id, :serial_id], unique: true
  end

  def self.down
    drop_table :issues
  end
end
