# -*- encoding : utf-8 -*-
Factory.define(:project) do |p|
  p.description { Factory.next(:string) }
  p.name { Factory.next(:unixname) }
  p.association :owner, :factory => :user
end
