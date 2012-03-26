# -*- encoding : utf-8 -*-
Factory.define(:repository) do |p|
  p.description { Factory.next(:string) }
  p.name { Factory.next(:unixname) }
  p.association :platform, :factory => :platform
end

Factory.define(:personal_repository, :parent => :repository) do |p|
  p.after_create {|r| 
  	r.platform.platform_type = 'personal'
    r.platform.visibility = 'hidden'
    r.platform.save!
  }
end
