FactoryGirl.define do
  factory :repository do
    description { FactoryGirl.generate(:string) }
    name { FactoryGirl.generate(:unixname) }
    association :platform, factory: :platform
  end

  factory :personal_repository, parent: :repository do
    association :platform, factory: :personal_platform
  end

end
