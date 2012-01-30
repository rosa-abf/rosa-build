# -*- encoding : utf-8 -*-
class AddIncludeReposToBuildLists < ActiveRecord::Migration
  def self.up
    add_column :build_lists, :include_repos, :text
  end

  def self.down
    remove_column :build_lists, :include_repos
  end
end
