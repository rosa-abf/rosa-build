# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :issue do
    title { FactoryGirl.generate(:string) }
    body { FactoryGirl.generate(:string) }
    association :project, :factory => :project
    association :user, :factory => :user
    association :assignee, :factory => :user
    state "open"
  end
end
