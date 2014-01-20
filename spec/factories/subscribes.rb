FactoryGirl.define do
  factory :subscribe do
    association :subscribeable, :factory => :issue
    association :user, :factory => :user
  end
end
