module AbfWorker
  class PublishBuildListContainerObserver < AbfWorker::BaseObserver
    @queue = :publish_build_list_container_observer

    def self.perform(options)
      bl = BuildList.find options['id']
      status = options['status'].to_i
      case status
      when COMPLETED
        bl.published
        update_results(bl, options)
      when FAILED
        bl.fail_publish
        update_results(bl, options)
      when CANCELED
        bl.fail_publish
        update_results(bl, options)
      end
    end

    def self.update_results(subject, options)
      results = (subject.results || []).
        map{ |r| r if r['file_name'] !~ /^abfworker\:\:publish\-build\-list\-container\-worker.*\.log$/ }.
        compact
      results += options['results']
      sort_results_and_save(subject, results)
    end

  end
end