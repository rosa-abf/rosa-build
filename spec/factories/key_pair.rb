# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :key_pair do
    association :repository
    association :user
    public FactoryGirl.generate(:string)
    secret FactoryGirl.generate(:string)
  end
end

