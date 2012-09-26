# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :product_build_list do
    association :product, :factory => :product
    status 0 # BUILD_COMPLETED
  end
end
