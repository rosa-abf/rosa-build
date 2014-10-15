FactoryGirl.define do
  factory :statistic do
    association :user
    association :project

    email { FactoryGirl.generate(:email) }
    project_name_with_owner { |u| u.project.name_with_owner }
    key { FactoryGirl.generate(:string) }
    activity_at { Time.now.utc }
  end
end
