FactoryGirl.define do
  factory :token do
    association :creator, :factory => :user
  end

  factory :platform_token, :parent => :token do
    association :subject, :factory => :platform
  end
end
