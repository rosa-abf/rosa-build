FactoryGirl.define do
  factory :pull_request do
    association :issue,         factory: :issue
    association :from_project,  factory: :project
    association :to_project,    factory: :project
    from_ref  { FactoryGirl.generate(:string) }
    to_ref    { FactoryGirl.generate(:string) }
  end
end
