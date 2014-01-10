# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :project_statistic do
    association :project, :factory => :project
    association :arch,    :factory => :arch
  end
end
