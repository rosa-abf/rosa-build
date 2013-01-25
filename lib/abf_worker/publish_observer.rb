module AbfWorker
  class PublishObserver < AbfWorker::BaseObserver
    @queue = :publish_observer


    def self.perform(options)
      status = options['status'].to_i
      return if status == STARTED # do nothing when publication started
      if options['type'] == 'resign'
        AbfWorker::BuildListsPublishTaskManager.unlock_repository options['id']
      else
        if options['extra']['create_container'] # Container has been created
          bl = BuildList.find(options['id'])
          bl.update_attributes(:container_path => "/#{bl.save_to_platform.name}/container/#{bl.id}")
        else
          update_rpm_builds options, status
        end
      end
    end

    def self.update_rpm_builds(options, status)
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

    class << self
      protected

      def update_results(subject, options)
        results = (subject.results || []).
          select{ |r| r['file_name'] !~ /^abfworker\:\:publish\-worker.*\.log$/ }
        results |= options['results']
        sort_results_and_save(subject, results)
      end
    end
  end
end