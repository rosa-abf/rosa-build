FactoryGirl.define do
  factory :pull_request do
    title { FactoryGirl.generate(:string) }
    body { FactoryGirl.generate(:string) }
    association :project, factory: :project
    association :user, factory: :user
    association :assignee, factory: :user
  end
end
