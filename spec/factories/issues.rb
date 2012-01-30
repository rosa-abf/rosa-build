# -*- encoding : utf-8 -*-
Factory.define(:issue) do |p|
  p.title { Factory.next(:string) }
  p.body { Factory.next(:string) }
  p.association :project, :factory => :project
  p.association :user, :factory => :user
  p.status "open"
end
