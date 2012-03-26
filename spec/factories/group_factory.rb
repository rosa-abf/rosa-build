# -*- encoding : utf-8 -*-
Factory.define(:group) do |g|
  g.uname { Factory.next(:uname) }
  g.description 'Description'
  g.association :owner, :factory => :user
end
