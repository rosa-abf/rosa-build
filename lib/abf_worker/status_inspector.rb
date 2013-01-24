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
          fill_status status, workers, worker
        end
        status
      end

      def fill_status(status, workers, worker)
        redis, key = Resque.redis, "queue:#{worker}_worker"
        status[worker] = {
          :count        => workers.count,
          :build_tasks  => workers.select{ |w| w.working? }.count,
          :tasks        => (redis.llen("#{key}_default") + redis.llen(key))
        }
      end

    end
  end
end