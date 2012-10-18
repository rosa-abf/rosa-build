# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :advisory do
    description { FactoryGirl.generate(:string) }
    update_type 'security'
  end
end
