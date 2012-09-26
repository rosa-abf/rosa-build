# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :flash_notify do
    body_ru { FactoryGirl.generate(:string) }
    body_en { FactoryGirl.generate(:string) }
    status "error"
    published true
  end
end

