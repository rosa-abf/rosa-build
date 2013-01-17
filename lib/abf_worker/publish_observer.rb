module AbfWorker
  class PublishObserver < AbfWorker::BaseObserver
    @queue = :publish_observer


    class << self
      def perform(options)
        status = options['status'].to_i
        return if status == STARTED # do nothing when publication started
        if options['type'] == 'resign'
          AbfWorker::BuildListsPublishTaskManager.unlock_repository options['id']
        else
          update_rpm_builds options
        end
      end

      protected

      def update_rpm_builds(options)
        build_lists = BuildList.where(:id => options['build_list_ids'])
        build_lists.each do |bl| 
          update_results(bl, options)
          case status
          when COMPLETED
            bl.published
            AbfWorker::BuildListsPublishTaskManager.cleanup_completed options['projects_for_cleanup']
          when FAILED, CANCELED
            bl.fail_publish
            AbfWorker::BuildListsPublishTaskManager.cleanup_failed options['projects_for_cleanup']
          end
          AbfWorker::BuildListsPublishTaskManager.unlock_build_list bl
        end
        bl = build_lists.first || BuildList.find(options['id'])
        AbfWorker::BuildListsPublishTaskManager.unlock_rep_and_platform bl
      end

      def update_results(subject, options)
        results = (subject.results || []).
          select{ |r| r['file_name'] !~ /^abfworker\:\:publish\-worker.*\.log$/ }
        results |= options['results']
        sort_results_and_save(subject, results)
      end

    end

  end
end