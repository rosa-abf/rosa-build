module AbfWorker
  class IsoWorkerObserver
    @queue = :iso_worker_observer

    def self.perform(options)
      status = options['status'].to_i
      pbl = ProductBuildList.find options['id']
      pbl.status = pbl.status == ProductBuildList::BUILD_CANCELING ?
        ProductBuildList::BUILD_CANCELED : status
      pbl.results = options['results'] if status != ProductBuildList::BUILD_STARTED
      pbl.save!
    end

  end
end