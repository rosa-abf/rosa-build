FactoryGirl.define do
  factory :build_script do
    association :project, factory: :project
    treeish { FactoryGirl.generate(:string) }
  end
end