module AbfWorker
  class IsoWorkerObserver
    BUILD_COMPLETED = 0
    BUILD_FAILED    = 1
    BUILD_PENDING   = 2
    BUILD_STARTED   = 3
    BUILD_CANCELED  = 4
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