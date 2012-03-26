# -*- encoding : utf-8 -*-
Factory.define(:private_user) do |p|
  p.login { Factory.next(:string) }
  p.password { Factory.next(:string) }
  p.association :platform, :factory => :platform
  p.association :user, :factory => :user
end
