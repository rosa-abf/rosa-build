# -*- encoding : utf-8 -*-
Factory.define(:repository) do |p|
  p.description { Factory.next(:string) }
  p.name { Factory.next(:unixname) }
  p.association :platform, :factory => :platform
  p.association :owner, :factory => :user
end

Factory.define(:personal_repository, :class => Repository) do |p|
  p.description { Factory.next(:string) }
  p.name { Factory.next(:unixname) }
  p.association :platform, :factory => :platform
  p.association :owner, :factory => :user

  p.after_create { |rep| 
  	rep.platform.platform_type = 'personal'
    rep.platform.visibility = 'hidden'
    rep.platform.save!
  }
end
