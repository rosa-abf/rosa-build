# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :repository do
    description { FactoryGirl.generate(:string) }
    name { FactoryGirl.generate(:unixname) }
    association :platform, :factory => :platform
  end

  factory :personal_repository, :parent => :repository do
    after_create {|r| 
    	r.platform.platform_type = 'personal'
      r.platform.visibility = 'hidden'
      r.platform.save!
    }
  end
end
