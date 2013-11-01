# -*- encoding : utf-8 -*-
module BuildListsHelper

  # See: app/assets/javascripts/angularjs/models/build_list.js.erb
  def build_list_status_color(status)
    case status
    when BuildList::BUILD_PUBLISHED, BuildList::SUCCESS
      'success'
    when BuildList::BUILD_ERROR, BuildList::FAILED_PUBLISH, BuildList::REJECTED_PUBLISH
      'error'
    when BuildList::TESTS_FAILED
      'warning'
    else
      'nocolor'
    end
  end

  def availables_main_platforms
    # Main platforms with repositories
    Platform.main.accessible_by(current_ability, :show)
            .includes(:repositories).where('repositories.id IS NOT NULL').order('platforms.name').uniq
  end

  def save_to_repositories(project)
    project.repositories.collect do |r|
      [
        "#{r.platform.name}/#{r.name}",
        r.id,
        {
          :publish_without_qa => r.publish_without_qa? ? 1 : 0,
          :platform_id        => r.platform.id,
          :default_arches     => (r.platform.platform_arch_settings.by_default.pluck(:arch_id).presence || Arch.where(:name => Arch::DEFAULT).pluck(:id)).join(' ')
        }
      ]
    end.sort_by { |col| col[0] }
  end

  def external_nodes
    BuildList::EXTERNAL_NODES.map do |type|
      [I18n.t("layout.build_lists.external_nodes.#{type}"), type]
    end
  end

  def mass_build_options
    options_from_collection_for_select(
      MassBuild.recent.limit(15),
      :id,
      :name
    )
  end

  def build_list_options_for_new_core
    [
      [I18n.t("layout.true_"), 1],
      [I18n.t("layout.false_"), 0]
    ]
  end

  def build_list_item_status_color(status)
    case status
    when BuildList::SUCCESS
      'success'
    # when BuildList::DEPENDENCIES_ERROR, BuildList::BUILD_ERROR, BuildList::Item::GIT_ERROR
    when BuildList::BUILD_ERROR, BuildList::Item::GIT_ERROR
      'error'
    else
      ''
    end
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
      {
        :text => str_version ? "#{shortest_hash_id item.version, hash_size}" : shortest_hash_id(item.version, hash_size),
        :href => commit_path(bl.project.owner, bl.project, item.version)
      }
    else
      {}
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

  def container_url(build_list = @build_list)
    url = "#{APP_CONFIG['downloads_url']}/#{build_list.save_to_platform.name}/container/#{build_list.id}/"
    url << "#{build_list.arch.name}/#{build_list.save_to_repository.name}/release/" if build_list.build_for_platform.distrib_type == 'mdv'
    url.html_safe
  end

  def can_publish_in_future?(bl)
    [BuildList::SUCCESS, BuildList::FAILED_PUBLISH, BuildList::BUILD_PUBLISHED, BuildList::TESTS_FAILED].include?(bl.status)
  end

  def log_reload_time_options
    t = I18n.t("layout.build_lists.log.reload_times").map { |i| i.reverse }

    options_for_select(t, t.first).html_safe
  end

  def log_reload_lines_options
    options_for_select([100, 200, 500, 1000, 1500, 2000], 1000).html_safe
  end

  def get_version_release build_list
    pkg = build_list.source_packages.first
    "#{pkg.version}-#{pkg.release}" if pkg.present?
  end
end
