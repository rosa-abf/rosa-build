# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :mass_build do
    association :platform
    #name FactoryGirl.generate(:name)
    association :user
    projects_list "first"
    arches { [ Arch.first.id ] }
    auto_publish true
    stop_build false
  end
end

