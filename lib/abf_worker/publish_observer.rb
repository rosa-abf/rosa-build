module AbfWorker
  class PublishObserver < AbfWorker::BaseObserver
    @queue = :publish_observer

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
        map{ |r| r if r['file_name'] !~ /^abfworker\:\:publish\-worker.*\.log$/ }.
        compact
      results += options['results']
      sort_results_and_save(subject, results)
    end

  end
end