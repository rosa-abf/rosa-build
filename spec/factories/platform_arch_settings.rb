FactoryGirl.define do
  factory :platform_arch_setting do
    association :platform, factory: :platform
    association :arch, factory: :arch
    default true
    time_living 777
  end
end
