# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :platform do
    description { FactoryGirl.generate(:string) }
    name { FactoryGirl.generate(:unixname) }
    platform_type 'main'
    distrib_type APP_CONFIG['distr_types'].first
    association :owner, :factory => :user
  end

  factory :platform_with_repos, :parent => :platform do
    repositories {|r| [r.association(:repository)]}
  end
  
  factory :personal_platform, :parent => :platform do
    platform_type 'personal'
  end
  
end
