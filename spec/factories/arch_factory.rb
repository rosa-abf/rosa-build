Factory.define(:arch) do |p|
  p.name { Factory.next(:string) }
end