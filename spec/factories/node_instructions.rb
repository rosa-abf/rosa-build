FactoryGirl.define do
  factory :node_instruction do
    association :user, factory: :system_user
    instruction { FactoryGirl.generate(:string) }
  end
end
