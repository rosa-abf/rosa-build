module AbfWorker
  class PublishObserver < AbfWorker::BaseObserver
    @queue = :publish_observer


    def self.perform(options)
      new(options, BuildList).perform
    end

    def perform
      return if status == STARTED # do nothing when publication started
      if options['type'] == 'resign'
        AbfWorker::BuildListsPublishTaskManager.unlock_repository options['id']
      else
        if options['extra']['regenerate'] # Regenerate metadata
          AbfWorker::BuildListsPublishTaskManager.unlock_rep_and_platform nil, options['extra']['lock_str']
        elsif options['extra']['create_container'] # Container has been created
          case status
          when COMPLETED
            subject.published_container
          when FAILED, CANCELED
            subject.fail_publish_container
          end
          update_results
        else
          update_rpm_builds
        end
      end
    end

    protected

    def update_rpm_builds
      build_lists = BuildList.where(:id => options['build_list_ids'])
      build_lists.each do |build_list| 
        update_results build_list
        case status
        when COMPLETED
          build_list.published
          AbfWorker::BuildListsPublishTaskManager.cleanup_completed options['projects_for_cleanup']
        when FAILED, CANCELED
          build_list.fail_publish
          AbfWorker::BuildListsPublishTaskManager.cleanup_failed options['projects_for_cleanup']
        end
        AbfWorker::BuildListsPublishTaskManager.unlock_build_list build_list
      end
      build_list = build_lists.first || subject
      AbfWorker::BuildListsPublishTaskManager.unlock_rep_and_platform build_list
    end

    def update_results(build_list = subject)
      results = (build_list.results || []).
        select{ |r| r['file_name'] !~ /^abfworker\:\:publish\-worker.*\.log$/ }
      results |= options['results']
      sort_results_and_save results, build_list
    end
  end
end