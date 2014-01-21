FactoryGirl.define do
  factory :private_user do
    login { FactoryGirl.generate(:string) }
    password { FactoryGirl.generate(:string) }
    association :platform, factory: :platform
    association :user, factory: :user
  end
end
