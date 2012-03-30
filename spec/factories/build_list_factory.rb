# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :build_list do
    association :user
    association :project
    association :pl, :factory => :platform_with_repos
    association :arch
    bpl {|bl| bl.pl}
    project_version "1.0"
    build_requires true
    update_type 'security'
    include_repos {|bl| bl.pl.repositories.map(&:id)}
    commit_hash '1234567890abcdef1234567890abcdef12345678'
  end

  factory :build_list_core, :parent => :build_list do
    bs_id { FactoryGirl.generate(:integer) }
  end
end
