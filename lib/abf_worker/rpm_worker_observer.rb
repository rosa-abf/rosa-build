module AbfWorker
  class RpmWorkerObserver
    @queue = :rpm_worker_observer

    def self.perform(options)
      bl = BuildList.find options['id']
      status = options['status'].to_i
      case status
      when 0
        bl.build_success
      when 1
        bl.build_error
      when 3
        bl.bs_id = bl.id
        bl.save
        bl.start_build
      end
      if status != 3
        bl.results = options['results']
        bl.save
      end
    end

  end
end