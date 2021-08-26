class Api::V1::JobsController < Api::V1::BaseController
  # QUEUES = %w(iso_worker_observer publish_observer rpm_worker_observer)
  # QUEUE_CLASSES = %w(AbfWorker::IsoWorkerObserver AbfWorker::PublishObserver AbfWorker::RpmWorkerObserver)
  QUEUES = %w(rpm_worker_observer)
  QUEUE_CLASSES = %w(AbfWorker::RpmWorkerObserver)

  before_action :authenticate_user!
  skip_after_action :verify_authorized

  def shift
    job_shift_sem = Redis::Semaphore.new(:job_shift_lock)
    job_shift_sem.lock do
      shifted_build_lists = Redis.current.smembers('abf_worker:shifted_build_lists').map(&:to_i)
      build_lists = if shifted_build_lists.empty?
        BuildList
      else
        BuildList.where.not(id: shifted_build_lists)
      end
      build_lists = build_lists.scoped_to_arch(arch_ids).
      for_status([BuildList::BUILD_PENDING, BuildList::RERUN_TESTS]).
      for_platform(platform_ids).where(builder: nil)

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
            @build_list = build_lists.where(user_id: uid, mass_build_id: nil).order(:created_at).first
          else
            @build_list = build_lists.where(user_id: uid).order(:created_at).first
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
      set_builder
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
      RpmBuildNode.create(
        id:            params[:uid],
        user_id:       current_user.id,
        system:        current_user.system?,
        worker_count:  params[:worker_count],
        busy_workers:  params[:busy_workers],
        host:          params[:host].to_s,
        query_string:  params[:query_string].to_s,
        last_build_id: params[:last_build_id].to_s
      ) rescue nil
    end
    render nothing: true
  end

  def status
    if params[:key] =~ /\Aabfworker::(rpm|iso)-worker-[\d]+::live-inspector\z/
      status = Redis.current.get(params[:key])
    end
    render json: { status: status }.to_json
  end

  def logs
    name = params[:name]
    if name =~ /abfworker::rpm-worker/
      if current_user.system? || current_user.id == BuildList.where(id: name.gsub(/[^\d]/, '')).first.try(:builder_id)
        BuildList.log_server.setex name, 15, params[:logs]
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
    @platform_ids ||= begin
      platform_types = params[:platform_types].to_s.split(',') & APP_CONFIG['distr_types']
      platforms = params[:platforms].to_s.split(',')
      platforms = platforms.present? ? Platform.where(name: platforms).pluck(:id) : []
      platforms |= Platform.main.where(distrib_type: platform_types).pluck(:id) if !platform_types.empty?
      platforms
    end
  end

  def arch_ids
    @arch_ids ||= begin
      arches = params[:arches].to_s.split(',')
      arches.present? ? Arch.where(name: arches).pluck(:id) : []
    end
  end

  def set_builder
    return unless @build_list
    @build_list.builder = current_user
    if !@build_list.valid?
      Raven.capture_message('Invalid build list', extra: { id: @build_list.id, errors: @build_list.errors.full_messages })
    end
    Redis.current.sadd('abf_worker:shifted_build_lists', @build_list.id)
    @build_list.save(validate: false)
  end

end
