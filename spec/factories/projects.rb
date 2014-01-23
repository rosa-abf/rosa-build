FactoryGirl.define do
  factory :project do
    description { FactoryGirl.generate(:string) }
    name { FactoryGirl.generate(:unixname) }
    association :owner, factory: :user
  end

  factory :group_project, parent: :project do
    association :owner, factory: :group
  end

  factory :project_with_commit, parent: :project do
    after(:build) {|project| fill_project project}
  end

  factory :group_project_with_commit, parent: :group_project do
    after(:build) {|project| fill_project project}
  end
end
