module AbfWorker
  class PublishObserver < AbfWorker::BaseObserver
    @queue = :publish_observer

    def self.perform(options)
      build_lists = BuildList.where(:id => options['build_list_ids'])
      status = options['status'].to_i
      build_lists.each do |bl| 
        update_results(bl, options)
        case status
        when COMPLETED
          bl.published
        when FAILED
          bl.fail_publish
        when CANCELED
          bl.fail_publish
        end
        AbfWorker::BuildListsPublishTaskManager.unlock_build_list bl
      end
      AbfWorker::BuildListsPublishTaskManager.unlock_rep_and_platform build_lists.first
    end

    def self.update_results(subject, options)
      results = (subject.results || []).
        select{ |r| r['file_name'] !~ /^abfworker\:\:publish\-worker.*\.log$/ }
      results |= options['results']
      sort_results_and_save(subject, results)
    end

  end
end