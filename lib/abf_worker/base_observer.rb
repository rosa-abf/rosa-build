module AbfWorker
  class BaseObserver
    COMPLETED = 0
    FAILED    = 1
    PENDING   = 2
    STARTED   = 3
    CANCELED  = 4

    def self.update_results(subject, options)
      results = (subject.results || []) + options['results']
      sort_results_and_save(subject, results)
    end

    def self.sort_results_and_save(subject, results)
      subject.results = results.sort_by{ |r| r['file_name'] }
      subject.save!
    end

  end
end