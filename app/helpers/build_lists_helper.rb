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

  def build_list_version_link(build_list, str_version = false)
    if build_list.commit_hash.present?
      link_to str_version ? "#{shortest_hash_id build_list.commit_hash} ( #{build_list.project_version} )" : shortest_hash_id(build_list.commit_hash),
        commit_path(build_list.project.owner, build_list.project, build_list.commit_hash)
    else
      build_list.project_version
    end
  end

  def container_url
    "http://#{request.host_with_port}/downloads#{@build_list.container_path}".html_safe
  end

  def build_list_log_url(log_type)
    "http://#{request.host_with_port}/#{@build_list.fs_log_path(log_type)}".html_safe
  end

  def log_reload_time_options
    t = I18n.t("layout.build_lists.log.reload_times").map { |i| i.reverse }

    options_for_select(t, t.first).html_safe
  end

  def log_reload_lines_options
    options_for_select([100, 200, 500, 1000, 1500, 2000], 1000).html_safe
  end
end
