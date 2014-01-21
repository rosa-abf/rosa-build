FactoryGirl.define do
  factory :build_list do
    association :user
    #association :project
    association :save_to_platform, factory: :platform_with_repos
    project { |bl|
      pr = FactoryGirl.create(:project_with_commit)
      bl.save_to_platform.repositories.first.projects << pr
      pr
    }
    association :arch
    build_for_platform {|bl| bl.save_to_platform}
    save_to_repository {|bl| bl.save_to_platform.repositories.first}
    update_type 'security'
    include_repos {|bl| bl.save_to_platform.repositories.map(&:id)}
    project_version 'master'
    commit_hash {|bl| Grit::Repo.new(bl.project.path).commits.first.id}
  end

  factory :build_list_with_attaching_project, parent: :build_list do
    before(:create) { |bl| attach_project_to_build_list bl }
  end

  factory :build_list_by_group_project, parent: :build_list do
    project { |bl|
      pr = FactoryGirl.create(:group_project_with_commit)
      bl.save_to_platform.repositories.first.projects << pr
      pr
    }
  end

  factory :build_list_package, class: BuildList::Package do
    association :build_list
    association :project
    association :platform
    fullname "test_package"
    name "test_package"
    version "3.1.12"
    release 6
    sha1 '4faae977e8b12baa267b566d2bec6e6182754ec4'
    package_type "source"
  end
end

def attach_project_to_build_list(bl)
  bl.save_to_platform ||= FactoryGirl.create(:platform_with_repos)
  bl.project.repositories << bl.save_to_platform.repositories.first
end
