# -*- encoding : utf-8 -*-

def create_build_list_with_project(factory, options, project)
  save_to_platform = FactoryGirl.create(:platform_with_repos)
  project.repositories << save_to_platform.repositories.first
  options ||= {}
  FactoryGirl.create(factory, options.merge({:project => project, :save_to_platform => save_to_platform}))
end