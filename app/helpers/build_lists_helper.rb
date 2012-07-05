# -*- encoding : utf-8 -*-
module BuildListsHelper
  def build_list_status_color(status)
    if [BuildList::BUILD_PUBLISHED, BuildServer::SUCCESS].include? status
      return 'success'
    end
    if [BuildServer::BUILD_ERROR, BuildServer::PLATFORM_NOT_FOUND,
        BuildServer::PROJECT_NOT_FOUND, BuildServer::PROJECT_VERSION_NOT_FOUND,
        BuildList::FAILED_PUBLISH, BuildList::REJECTED_PUBLISH].include? status
      return 'error'
    end

    'nocolor'
  end

  def build_list_item_status_color(status)
    if BuildServer::SUCCESS == status
      return 'success'
    end
    if [BuildServer::DEPENDENCIES_ERROR, BuildServer::BUILD_ERROR, BuildList::Item::GIT_ERROR].include? status
      return 'error'
    end

    ''
  end

  def build_list_classified_update_types
    advisoriable    = BuildList::RELEASE_UPDATE_TYPES.map do |el|
      [el, {:class => 'advisoriable'}]
    end
    nonadvisoriable = (BuildList::UPDATE_TYPES - BuildList::RELEASE_UPDATE_TYPES).map do |el|
      [el, {:class => 'nonadvisoriable'}]
    end

    return advisoriable + nonadvisoriable
  end
end
