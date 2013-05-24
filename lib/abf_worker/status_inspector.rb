module AbfWorker
  class StatusInspector

    class << self
      def projects_status
        get_status(:rpm, :publish) { |w, worker|
          w.to_s =~ /#{worker}_worker_default/
        }
      end

      def products_status
        get_status(:iso) { |w, worker|
          str = w.to_s
          str =~ /iso_worker/ && str !~ /observer/
        }
      end

      protected

      def get_status(*queues)
        status = {}
        queues.each do |worker|
          workers = Resque.workers.select{ |w| yield w, worker }
          status[worker] = status_of_worker workers, worker
        end
        status
      end

      def status_of_worker(workers, worker)
        redis, key = Resque.redis, "queue:#{worker}_worker"
        default_tasks, tasks = redis.llen("#{key}_default"), redis.llen(key)
        {
          :count              => workers.count,
          :build_tasks        => workers.select{ |w| w.working? }.count,
          :default_tasks      => redis.llen("#{key}_default"),
          :low_tasks          => redis.llen(key)
        }
      end

    end
  end
end