module AbfWorker
  class StatusInspector

    def self.get_status
      redis, all_workers = Resque.redis, Resque.workers
      status = {}
      [:rpm, :publish].each do |worker|
        workers = all_workers.select{ |w| w.to_s =~ /#{worker}_worker_default/ }
        key = "queue:#{worker}_worker"
        status[worker] = {
          :count        => workers.count,
          :build_tasks  => workers.select{ |w| w.working? }.count,
          :tasks        => (redis.llen("#{key}_default") + redis.llen(key))
        }
      end
      status
    end

  end
end