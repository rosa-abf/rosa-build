# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :product do
    name { FactoryGirl.generate(:string) }
    association :platform, :factory => :platform
    association :project, :factory => :project
    before(:create) { |p|
      p.project.repo.index.add('test', 'TEST')
      p.project.repo.index.commit('Test commit')
    }
  end
end
