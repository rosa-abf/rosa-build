Factory.define(:repository) do |p|
  p.name { Factory.next(:string) }
  p.unixname { Factory.next(:unixname) }
  p.association :platform, :factory => :platform
  p.association :owner, :factory => :user
end