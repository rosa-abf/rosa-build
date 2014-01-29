module AbfWorker
  class BaseObserver
    COMPLETED     = 0
    FAILED        = 1
    PENDING       = 2
    STARTED       = 3
    CANCELED      = 4
    TESTS_FAILED  = 5

    attr_accessor :status, :options

    def initialize(options, subject_class)
      @status   = options['status'].to_i
      @options  = options
      @subject_class = subject_class
    end

    def perform
      raise NotImplementedError, "You should implement this method"
    end

    protected

    def subject
      @subject ||= @subject_class.find options['id']
    end

    def update_results
      results = (subject.results || []) + (options['results'] || [])
      sort_results_and_save results
    end

    def sort_results_and_save(results, item = subject)
      item.results = results.sort_by{ |r| r['file_name'] }
      item.save(validate: false)
    end

  end
end