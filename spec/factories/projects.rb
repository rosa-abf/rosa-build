# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :project do
    description { FactoryGirl.generate(:string) }
    name { FactoryGirl.generate(:unixname) }
    association :owner, :factory => :user
  end
end
