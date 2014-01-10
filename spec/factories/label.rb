FactoryGirl.define do
  factory :label do
    name { FactoryGirl.generate(:string) }
    color 'FFF'
    association :project, :factory => :project
  end
end