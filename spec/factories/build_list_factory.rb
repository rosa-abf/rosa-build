# -*- encoding : utf-8 -*-
Factory.define(:build_list) do |p|
  p.association :user
  p.association :project
  p.association :pl, :factory => :platform_with_repos
  p.association :arch
  p.bpl {|bl| bl.pl}
  p.project_version "1.0"
  p.build_requires true
  p.update_type 'security'
  p.include_repos {|bl| bl.pl.repositories.map(&:id)}
  p.commit_hash '1234567890abcdef1234567890abcdef12345678'
end

Factory.define(:build_list_core, :parent => :build_list) do |p|
  p.bs_id { Factory.next(:integer) }
end
