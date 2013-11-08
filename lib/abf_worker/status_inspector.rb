module AbfWorker
  class StatusInspector

    class << self
      def projects_status
        Rails.cache.fetch([AbfWorker::StatusInspector, :projects_status], :expires_in => 10.seconds) do
          result = get_status(:rpm, :publish) { |w, worker| w.to_s =~ /#{worker}_worker_default/ }
          nodes = RpmBuildNode.total_statistics
          result[:rpm][:workers] += nodes[:systems]
          result[:rpm][:build_tasks] += nodes[:busy]
          result[:rpm][:other_workers] = nodes[:others]
          result
        end
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
          :workers            => workers.count,
          :build_tasks        => workers.select{ |w| w.working? }.count,
          :default_tasks      => default_tasks,
          :low_tasks          => tasks,
          :tasks              => (default_tasks + tasks)
        }
      end

    end
  end
end