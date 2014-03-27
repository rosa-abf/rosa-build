FactoryGirl.define do
  factory :comment do
    body { FactoryGirl.generate(:string) }
    association :user, factory: :user
    association :commentable, factory: :issue
    project { |c| c.commentable.project }
  end
end
