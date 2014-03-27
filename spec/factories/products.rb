FactoryGirl.define do
  factory :product do
    name { FactoryGirl.generate(:string) }
    association :platform, factory: :platform
    association :project, factory: :project_with_commit
    time_living 150

    # see: before_validation in ProductBuildList model
    before(:create) { Arch.find_or_create_by(name: 'x86_64') }
  end
end
