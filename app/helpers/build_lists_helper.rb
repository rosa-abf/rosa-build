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

   def build_list_item_version_link(item, str_version = false)
    hash_size=5
    if item.version =~ /^[\da-z]+$/ && item.name == item.build_list.project.name
      bl = item.build_list
      link_to str_version ? "#{shortest_hash_id item.version, hash_size}" : shortest_hash_id(item.version, hash_size),
        commit_path(bl.project.owner, bl.project, item.version)
    else
      ''
    end
  end 

  def build_list_version_link(bl, str_version = false)
    hash_size=5
    if bl.commit_hash.present?
      if bl.last_published_commit_hash.present?
        link_to "#{shortest_hash_id bl.last_published_commit_hash, hash_size}...#{shortest_hash_id bl.commit_hash, hash_size}",
                diff_path(bl.project.owner, bl.project, bl.last_published_commit_hash) + "...#{bl.commit_hash}"
      else
        link_to str_version ? "#{shortest_hash_id bl.commit_hash, hash_size}" : shortest_hash_id(bl.commit_hash, hash_size),
          commit_path(bl.project.owner, bl.project, bl.commit_hash)
      end
    else
      bl.project_version
    end
  end

  def product_build_list_version_link(bl, str_version = false)
    if bl.commit_hash.present?
      link_to str_version ? "#{shortest_hash_id bl.commit_hash} ( #{bl.project_version} )" : shortest_hash_id(bl.commit_hash),
        commit_path(bl.project.owner, bl.project, bl.commit_hash)
    else
      bl.project_version
    end
  end

  def container_url
    if @build_list.new_core?
      @build_list.container_path
    else
      "http://#{request.host_with_port}/downloads#{@build_list.container_path}".html_safe
    end
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
