Factory.define(:subscribe) do |p|
  p.association :subscribeable, :factory => :issue
  p.association :user, :factory => :user
end
