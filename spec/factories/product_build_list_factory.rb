# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :product_build_list do
    association :product, :factory => :product
  end
end
