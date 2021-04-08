json.build_list do
  if !@build_list.in_work? && @build_list.started_at
    json.human_duration @build_list.human_duration
  elsif @build_list.in_work?
    json.human_duration "#{@build_list.human_current_duration} / #{@build_list.human_average_build_time}"
  end

  json.cache! [@build_list, current_user], expires_in: 1.minute do
    json.(@build_list, :id, :container_status, :status)
    json.(@build_list, :update_type)
    json.(@build_list, :hostname, :fail_reason)
    json.updated_at @build_list.updated_at
    json.updated_at_utc @build_list.updated_at.strftime('%Y-%m-%d %H:%M:%S UTC')


    json.can_publish policy(@build_list).publish?
    json.can_publish_into_testing policy(@build_list).publish_into_testing? && @build_list.can_publish_into_testing?
    json.can_cancel @build_list.can_cancel?
    json.can_create_container @build_list.can_create_container?
    json.can_reject_publish @build_list.can_reject_publish?

    json.extra_build_lists_published @build_list.extra_build_lists_published?
    json.can_publish_in_future can_publish_in_future?(@build_list)
    json.can_publish_into_repository @build_list.can_publish_into_repository?


    json.container_path container_url if @build_list.container_published?

    json.publisher do
      json.fullname @build_list.publisher.try(:fullname)
      json.path user_path(@build_list.publisher)
    end if @build_list.publisher

    json.builder do
      json.fullname @build_list.builder.try(:fullname)
      json.path user_path(@build_list.builder)
    end if @build_list.builder && (!@build_list.builder.system? || current_user.try(:admin?))

    json.advisory do
      json.(@build_list.advisory, :description, :advisory_id)
      json.path advisory_path(@build_list.advisory)
    end if @build_list.advisory

    json.results @build_list.results do |result|
      json.file_name result['file_name']
      json.sha1 result['sha1']
      json.size result['size']

      json.created_at Time.zone.at(result['timestamp']).to_s if result['timestamp']

      json.url file_store_results_url(result['sha1'], result['file_name'])
    end if @build_list.new_core? && @build_list.results.present?

    dependent_projects_exists = false
    json.packages @build_list.packages do |package|
      json.(package, :id, :name, :fullname, :release, :version, :sha1, :epoch)
      json.url "#{APP_CONFIG['file_store_url'].gsub('http://', 'https://')}/api/v1/file_stores/#{package.sha1}" if package.sha1
      if package.size == 0
        json.size 'N/A'
      else
        json.size bytes_to_size(package.size)
      end

      if @build_list.save_to_platform.main?
        json.dependent_projects dependent_projects(package) do |project, packages|
          json.url project_path(project.name_with_owner)
          json.name project.name_with_owner
          json.dependent_packages packages
          json.new_url new_project_build_list_path(project)

          dependent_projects_exists = true
        end
      else
        json.dependent_projects []
      end
    end if @build_list.packages.present?

    json.dependent_projects_exists dependent_projects_exists

    json.item_groups do |group|
      @item_groups.each_with_index do |group, level|
        json.group group do |item|
          json.(item, :name, :status)
          json.path build_list_item_version_link item
          json.level level
        end
      end
    end if @item_groups.present?
  end

end
