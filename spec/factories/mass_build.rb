FactoryGirl.define do
  factory :mass_build do
    association :save_to_platform, factory: :platform
    association :user
    projects_list "first"
    arches { [ Arch.where(name: 'x86_64').first_or_create.id ] }
    auto_publish true
    stop_build false
  end
end

