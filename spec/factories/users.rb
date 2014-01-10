FactoryGirl.define do
  factory :user do
    email { FactoryGirl.generate(:email) }
    name { FactoryGirl.generate(:string) }
    uname { FactoryGirl.generate(:uname) }
    password '123456'
    password_confirmation {|u| u.password}
    confirmed_at { Time.now.utc }
    after(:create) { |u| u.send(:new_user_notification) }
  end

  factory :admin, :parent => :user do
    role 'admin'
  end
end
