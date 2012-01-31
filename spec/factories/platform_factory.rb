# -*- encoding : utf-8 -*-
Factory.define(:platform) do |p|
  p.description { Factory.next(:string) }
  p.name { Factory.next(:unixname) }
  p.platform_type 'main'
  p.distrib_type APP_CONFIG['distr_types'].first
  p.association :owner, :factory => :user
end

Factory.define(:platform_with_repos, :parent => :platform) do |p|
  p.repositories {|r| [r.association(:repository)]}
end
