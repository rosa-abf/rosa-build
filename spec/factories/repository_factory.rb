Factory.define(:repository) do |p|
  p.name { Factory.next(:string) }
  p.unixname { Factory.next(:unixname) }
  p.association :platform, :factory => :platform
  p.association :owner, :factory => :user
end

Factory.define(:personal_repository, :class => Repository) do |p|
  p.name { Factory.next(:string) }
  p.unixname { Factory.next(:unixname) }
  p.association :platform, :factory => :platform
  p.association :owner, :factory => :user

  p.after_create { |rep| 
  	rep.platform.platform_type = 'personal'
  }
end