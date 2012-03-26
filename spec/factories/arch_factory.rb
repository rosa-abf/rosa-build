# -*- encoding : utf-8 -*-
Factory.define(:arch) do |p|
  p.name { Factory.next(:string) }
end
