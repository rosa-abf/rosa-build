FactoryGirl.define do
  factory :mass_build do
    association :save_to_platform, :factory => :platform
    association :user
    projects_list "first"
    arches { [ Arch.find_or_create_by_name('x86_64').id ] }
    auto_publish true
    stop_build false
  end
end

