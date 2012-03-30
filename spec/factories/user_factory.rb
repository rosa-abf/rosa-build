# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :user do
    email { FactoryGirl.generate(:email) }
    name { FactoryGirl.generate(:string) }
    uname { FactoryGirl.generate(:uname) }
    password '123456'
    password_confirmation {|u| u.password}
    confirmed_at { Time.current }
  end

  factory :admin, :parent => :user do
    role 'admin'
  end
end
