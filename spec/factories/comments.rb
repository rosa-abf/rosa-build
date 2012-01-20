Factory.define(:comment) do |p|
  p.body { Factory.next(:string) }
  p.association :user, :factory => :user
  p.association :commentable, :factory => :issue
end

Factory.define(:commit_comment, :class => 'Comment') do |p|
  p.body { Factory.next(:string) }
  p.association :user, :factory => :user
  p.commentable_type 'Grit::Commit'
  p.commentable_id 'asdf'
  p.project nil
end