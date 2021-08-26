module AbfWorker
  class PublishObserver < AbfWorker::BaseObserver
    @queue = :publish_observer

    def self.perform(options)
      new(options, BuildList).perform
    end

    def perform
      return if status == STARTED # do nothing when publication started
      extra = options['extra']
      repository_status = RepositoryStatus.where(id: extra['repository_status_id']).first
      begin

        if extra['regenerate'] || extra['regenerate_platform']
          log_sha1 = (options['results'].try(:first) || {}).fetch('sha1', nil)
        end

        if extra['regenerate'] # Regenerate metadata
          repository_status.last_regenerated_at = Time.now.utc
          repository_status.last_regenerated_status = status
          repository_status.last_regenerated_log_sha1 = log_sha1
        elsif extra['regenerate_platform'] # Regenerate metadata for Software Center
          if platform = Platform.where(id: extra['platform_id']).first
            platform.last_regenerated_at = Time.now.utc
            platform.last_regenerated_status = status
            platform.last_regenerated_log_sha1 = log_sha1
            platform.ready
          end
        elsif extra['create_container'] # Container has been created
          case status
          when COMPLETED
            subject.published_container
          when FAILED, CANCELED
            subject.fail_publish_container
          end
          update_results
        elsif !extra['resign'] # Simple publish
          bls = extra['build_lists_for_cleanup_from_testing']
          if status != COMPLETED && bls.present?
            AbfWorkerService::Base.cleanup_packages_from_testing(
              repository_status.platform_id,
              repository_status.repository_id,
              bls
            )
          end
          update_rpm_builds
        end
      ensure
        repository_status.ready if repository_status.present?
      end
    end

    protected

    def update_rpm_builds
      build_lists = BuildList.where(id: options['build_list_ids'])
      build_lists.each do |build_list|
        update_results build_list
        case status
        when COMPLETED
          if build_list.build_publish?
            # 'update_column' - when project of build_list has been removed from repository
            build_list.published || build_list.update_column(:status, BuildList::BUILD_PUBLISHED)
          elsif build_list.build_publish_into_testing?
            build_list.published_into_testing || build_list.update_column(:status, BuildList::BUILD_PUBLISHED_INTO_TESTING)
          end
        when FAILED, CANCELED
          if build_list.build_publish?
            build_list.fail_publish || build_list.update_column(:status, BuildList::FAILED_PUBLISH)
          elsif build_list.build_publish_into_testing?
            build_list.fail_publish_into_testing || build_list.update_column(:status, BuildList::FAILED_PUBLISH_INTO_TESTING)
          end
        end
      end
      $redis.with do |r|
        r.multi do
          options['build_list_ids'].each do |blid|
            r.lrem AbfWorkerService::Base::LOCKED_BUILD_LISTS, 0, blid
          end
        end
      end

      case status
      when COMPLETED
        AbfWorkerService::Base.cleanup_completed options['projects_for_cleanup']
      when FAILED, CANCELED
        AbfWorkerService::Base.cleanup_failed options['projects_for_cleanup']
      end
    end

    def update_results(build_list = subject)
      results = (build_list.results || []).
        select{ |r| r['file_name'] !~ /^abfworker\:\:publish\-(container\-)*worker.*\.log$/ }
      results |= options['results']
      sort_results_and_save results, build_list
    end
  end
end