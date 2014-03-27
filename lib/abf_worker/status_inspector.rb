module AbfWorker
  class StatusInspector

    class << self
      def projects_status
        Rails.cache.fetch([AbfWorker::StatusInspector, :projects_status], expires_in: 10.seconds) do
          result = get_status(:rpm, :publish) { |w, worker| w.to_s =~ /#{worker}_worker_default/ }
          nodes = RpmBuildNode.total_statistics
          result[:rpm][:workers]        += nodes[:systems]
          result[:rpm][:build_tasks]    += nodes[:busy]
          result[:rpm][:other_workers]  = nodes[:others]

          external_bls = BuildList.for_status(BuildList::BUILD_PENDING).external_nodes(:everything).count
          result[:rpm][:default_tasks] += external_bls + count_of_tasks('user_build_')

          mass_build_tasks = count_of_tasks('mass_build_')
          result[:rpm][:low_tasks] += mass_build_tasks
          result[:rpm][:tasks] += external_bls + mass_build_tasks
          result
        end
      end

      def count_of_tasks(regexp)
        Redis.current.smembers('resque:queues').
          select{ |q| q =~ /#{regexp}/ }.
          map{ |q| Redis.current.llen("resque:queue:#{q}") }.sum
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
        key = "resque:queue:#{worker}_worker"
        default_tasks, tasks = Redis.current.llen("#{key}_default"), Redis.current.llen(key)
        {
          workers:       workers.count,
          build_tasks:   workers.select{ |w| w.working? }.count,
          default_tasks: default_tasks,
          low_tasks:     tasks,
          tasks:         (default_tasks + tasks)
        }
      end
    end
  end
end
