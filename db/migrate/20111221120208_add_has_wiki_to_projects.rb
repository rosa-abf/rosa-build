# -*- encoding : utf-8 -*-
class AddHasWikiToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :has_wiki, :boolean, :default => false
  end

  def self.down
    remove_column :projects, :has_wiki
  end
end
