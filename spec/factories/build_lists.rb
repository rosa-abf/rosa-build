# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :build_list do
    association :user
    #association :project
    association :save_to_platform, :factory => :platform_with_repos
    project { |bl| FactoryGirl.create(:project, :repositories => [bl.save_to_platform.repositories.first]) }
    association :arch
    build_for_platform {|bl| bl.save_to_platform}
    save_to_repository {|bl| bl.save_to_platform.repositories.first}
    build_requires true
    update_type 'security'
    include_repos {|bl| bl.save_to_platform.repositories.map(&:id)}
    project_version 'latest_master'
    after(:build) {|bl| test_git_commit bl.project }
  end

  factory :build_list_core, :parent => :build_list do
    bs_id { FactoryGirl.generate(:integer) }
  end

  factory :build_list_by_group_project, :parent => :build_list_core do
    project { |bl| FactoryGirl.create(:group_project, :repositories => [bl.save_to_platform.repositories.first]) }
  end

  factory :build_list_package, :class => BuildList::Package do
    association :build_list
    association :project
    association :platform
    fullname "test_package"
    name "test_package"
    version "3.1.12"
    release 6
    package_type "source"
  end
end
