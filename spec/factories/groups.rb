FactoryGirl.define do
  factory :group do
    uname { FactoryGirl.generate(:uname) }
    description 'Description'
    association :owner, factory: :user
  end
end
