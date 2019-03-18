class AbfWorkerStatusPresenter < ApplicationPresenter

  def initialize
  end

  def projects_status
    Rails.cache.fetch([AbfWorkerStatusPresenter, :projects_status], expires_in: 10.seconds) do
      result = get_status(:rpm, :publish) { |w, worker| w.to_s =~ /#{worker}_worker_default/ }
      nodes = RpmBuildNode.total_statistics
      result[:rpm][:workers]        += nodes[:systems]
      result[:rpm][:build_tasks]    += nodes[:busy]
      result[:rpm][:other_workers]  = nodes[:others]

      external_bls = BuildList.for_status(BuildList::BUILD_PENDING).where(mass_build_id: nil).count
      result[:rpm][:default_tasks] = external_bls

      mass_build_tasks = BuildList.for_status(BuildList::BUILD_PENDING).where.not(mass_build_id: nil).count
      result[:rpm][:low_tasks] = mass_build_tasks
      result[:rpm][:tasks] += external_bls + mass_build_tasks
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
