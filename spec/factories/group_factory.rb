Factory.define(:group) do |g|
  g.name { Factory.next(:string) }
  g.uname { Factory.next(:uname) }
  g.association :owner, :factory => :user
end
