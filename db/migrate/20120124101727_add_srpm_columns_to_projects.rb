class AddSrpmColumnsToProjects < ActiveRecord::Migration[8.1]
  def self.up
    change_table :projects do |t|
#      t.has_attached_file :srpm
      t.attachment
    end
  end

  def self.down
    drop_attached_file :projects, :srpm
  end
end
