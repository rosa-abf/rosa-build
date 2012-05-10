# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :build_list do
    association :user
    association :project
    association :save_to_platform, :factory => :platform_with_repos
    association :arch
    build_for_platform {|bl| bl.save_to_platform}
    project_version "1.0"
    build_requires true
    update_type 'security'
    include_repos {|bl| bl.save_to_platform.repositories.map(&:id)}
    commit_hash '1234567890abcdef1234567890abcdef12345678'
  end

  factory :build_list_core, :parent => :build_list do
    bs_id { FactoryGirl.generate(:integer) }
  end
end
