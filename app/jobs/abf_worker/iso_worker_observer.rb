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

        case options['exit_status'].to_i
        when ProductBuildList::BUILD_COMPLETED_PARTIALLY
          subject.build_success_partially
        else
          subject.build_error
        end

      when STARTED
        subject.start_build
      when CANCELED
        subject.build_canceled
      end
      update_results if status != STARTED
    end

  end
end