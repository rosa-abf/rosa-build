FactoryGirl.define do
  factory :comment do
    body { FactoryGirl.generate(:string) }
    association :user, factory: :user
    association :commentable, factory: :issue
    project { |c| c.commentable.project }
    after(:create) { |c| c.send(:new_comment_notifications) }
  end
end
