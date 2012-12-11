module AbfWorker
  class IsoWorkerObserver
    extend AbfWorker::ObserverHelper
    @queue = :iso_worker_observer

    def self.perform(options)
      status = options['status'].to_i
      pbl = ProductBuildList.find options['id']
      case status
      when BUILD_COMPLETED
        pbl.build_success
      when BUILD_FAILED
        pbl.build_error
      when BUILD_STARTED
        pbl.start_build
      when BUILD_CANCELED
        pbl.build_canceled
      end
      if status != BUILD_STARTED
        pbl.results = options['results']
        pbl.save!
      end
    end

  end
end