module AbfWorker
  class IsoWorkerObserver < AbfWorker::BaseObserver
    @queue = :iso_worker_observer

    def self.perform(options)
      new(options, ProductBuildList).perform
    end

    def perform
      case status
      when COMPLETED
        subject.build_success
      when FAILED
        subject.build_error
      when STARTED
        subject.start_build
      when CANCELED
        subject.build_canceled
      end
      update_results if status != STARTED
    end

  end
end