Factory.define(:comment) do |p|
  p.body { Factory.next(:string) }
  p.association :user, :factory => :user
  p.association :commentable, :factory => :issue
end
