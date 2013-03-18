FactoryGirl.define do
  factory :product do
    name { FactoryGirl.generate(:string) }
    association :platform, :factory => :platform
    association :project, :factory => :project_with_commit
    time_living 150
  end
end
