module AbfWorker
  class IsoWorkerObserver < AbfWorker::BaseObserver
    @queue = :iso_worker_observer

    def self.perform(options)
      status = options['status'].to_i
      pbl = ProductBuildList.find options['id']
      case status
      when COMPLETED
        pbl.build_success
      when FAILED
        pbl.build_error
      when STARTED
        pbl.start_build
      when CANCELED
        pbl.build_canceled
      end
      pbl.build_canceled if pbl.build_canceling?
      if status != STARTED
        update_results(pbl, options)
      end
    end

  end
end