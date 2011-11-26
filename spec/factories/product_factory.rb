Factory.define(:product) do |p|
  p.name { Factory.next(:string) }
  p.association :platform, :factory => :platform
end
