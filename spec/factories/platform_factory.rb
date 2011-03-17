Factory.define(:platform) do |p|
  p.name { Factory.next(:string) }
  p.unixname { Factory.next(:string) }
end