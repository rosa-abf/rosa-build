FactoryGirl.define do
  factory :platform do
    name { FactoryGirl.generate(:unixname) }
    description { FactoryGirl.generate(:string) }
    platform_type 'main'
    distrib_type APP_CONFIG['distr_types'].first
    association :owner, :factory => :user

    factory :platform_with_repos do
      after(:create) {|p| FactoryGirl.create_list(:repository, 1, platform: p)}
    end

    factory :personal_platform do
      platform_type 'personal'
    end
  end
end
