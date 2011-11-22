Factory.define(:project) do |p|
  p.name { Factory.next(:string) }
  p.unixname { Factory.next(:unixname) }
  p.association :owner, :factory => :user
end