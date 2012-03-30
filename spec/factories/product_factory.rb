# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :product do
    name { FactoryGirl.generate(:string) }
    association :platform, :factory => :platform
  end
end
