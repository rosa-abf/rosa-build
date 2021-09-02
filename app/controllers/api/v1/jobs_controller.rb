class Api::V1::JobsController < Api::V1::BaseController
  QUEUES = %w(rpm_worker_observer)
  QUEUE_CLASSES = %w(AbfWorker::RpmWorkerObserver)

  before_action :authenticate_user!
  skip_after_action :verify_authorized

  def shift
    $redis.with do |r|
      job_shift_sem = Redis::Semaphore.new(:job_shift_lock, redis: r)
      job_shift_sem.lock do
        shifted_build_lists = r.smembers('abf_worker:shifted_build_lists')
        build_lists = if shifted_build_lists.empty?
          BuildList
        else
          BuildList.where.not(id: shifted_build_lists)
        end
        build_lists = build_lists.scoped_to_arch(arch_ids).for_platform(platform_ids).
        for_status([BuildList::BUILD_PENDING, BuildList::RERUN_TESTS])

        if current_user.system?
          build_lists = build_lists.where(external_nodes: ["", nil, "everything"])
          uid = build_lists.where(mass_build_id: nil).pluck('DISTINCT user_id').sample
          if !uid
            uid = build_lists.pluck('DISTINCT user_id').sample
            mass_build = true
          else
            mass_build = false
          end

          if uid
            if !mass_build
              @build_list = build_lists.where(user_id: uid, mass_build_id: nil).order(:id).limit(1).first
            else
              @build_list = build_lists.where(user_id: uid).order(:id).limit(1).first
            end
          end
        else
          tmp           = build_lists.external_nodes(:owned).for_user(current_user).order(:created_at)
          @build_list   = tmp.where(mass_build_id: nil).first
          @build_list ||= tmp.first
          if !@build_list
            tmp           = BuildListPolicy::Scope.new(current_user, build_lists).owned.
                            external_nodes(:everything).readonly(false).order(:created_at)
            @build_list ||= tmp.where(mass_build_id: nil).first
            @build_list ||= tmp.first
          end
        end
        if @build_list
          r.sadd('abf_worker:shifted_build_lists', @build_list.id)
          @build_list.builder = current_user
          @build_list.save(validate: false)
        end
      end
    end

    job = {
      worker_queue: '',
      worker_class: '',
      :worker_args  => [@build_list.abf_worker_args]
    } if @build_list
    render json: Oj.dump({ job: job }, mode: :compat)
  end

  def statistics
    if params[:uid].present?
      RpmBuildNode.create_or_update(
        id:            params[:uid],
        host:          params[:host].to_s,
        user_id:       current_user.id,
        system:        current_user.system?,
        busy:          params[:busy_workers] == 1,
        query_string:  params[:query_string].to_s,
        last_build_id: params[:last_build_id].to_s
      ) rescue nil
    end
    render nothing: true
  end

  def status
    if params[:key] =~ /\Aabfworker::(rpm|iso)-worker-[\d]+::live-inspector\z/
      status = $redis.with { |r| r.get(params[:key]) }
    end
    render json: { status: status }.to_json
  end

  def logs
    name = params[:name]
    if name.start_with?('abfworker::rpm-worker-')
      if current_user.system? || current_user.id == BuildList.find_by_id(id: name.split('-').second).try(:builder_id)
        $redis.with { |r| r.setex name, 15, params[:logs] }
      end
    end
    render nothing: true
  end

  def feedback
    worker_queue = params[:worker_queue]
    worker_class = params[:worker_class]
    if QUEUES.include?(worker_queue) && QUEUE_CLASSES.include?(worker_class)
      worker_args = (params[:worker_args] || []).first || {}
      worker_args = worker_args.merge(feedback_from_user: current_user.id)
      Resque.push worker_queue, 'class' => worker_class, 'args' => [worker_args]
      render nothing: true
    else
      render nothing: true, status: 403
    end
  end

  protected

  def platform_ids
    platforms = params[:platforms].to_s.split(',')
    platforms = platforms.present? ? Platform.where(name: platforms).pluck(:id) : []

    platform_types = params[:platform_types].to_s.split(',') & APP_CONFIG['distr_types']
    if !platform_types.empty?
      distrib_type_to_ids = Rails.cache.fetch('distrib_type_to_ids', expires_in: 1.hour) do
        res = {}
        Platform.main.pluck(:distrib_type, :id).each do |item|
          res[item[0]] ||= []
          res[item[0]] << item[1]
        end
        res
      end
      platform_types.each do |type|
        platforms |= distrib_type_to_ids[type]
      end
    end
    platforms
  end

  def arch_ids
    arches = Rails.cache.fetch("arches_to_ids", expires_in: 24.hours) do
      Arch.pluck(:name, :id).to_h
    end
    params[:arches].to_s.split(',').uniq.map { |arch| arches[arch] }.compact
  end

end
