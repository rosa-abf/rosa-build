FactoryGirl.define do
  factory :advisory do
    description { FactoryGirl.generate(:string) }
    update_type 'security'
  end
end
