# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :mass_build do
    association :platform
    #name FactoryGirl.generate(:name)
    association :user
    repositories { |mb| [ mb.platform.repositories.first.id ] }
    arches { [ Arch.first.id ] }
    auto_publish true
  end
end

