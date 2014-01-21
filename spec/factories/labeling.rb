FactoryGirl.define do
  factory :labeling do
    association :project, factory: :project
    association :label,   factory: :label
  end
end