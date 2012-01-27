class AddSrpmColumnsToProjects < ActiveRecord::Migration
  def self.up
    change_table :projects do |t|
      t.has_attached_file :srpm
    end
  end

  def self.down
    drop_attached_file :projects, :srpm
  end
end
