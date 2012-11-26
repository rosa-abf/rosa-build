module AbfWorker
  class RpmWorkerObserver
    @queue = :rpm_worker_observer

    def self.perform(options)
      bl = BuildList.find options['id']
      case options['status'].to_i
      when 0
        bl.build_success
      when 1
        bl.build_error
      when 3
        bl.start_build
      end
    end

  end
end