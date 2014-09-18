class Api::V1::JobsController < Api::V1::BaseController
  # QUEUES = %w(iso_worker_observer publish_observer rpm_worker_observer)
  # QUEUE_CLASSES = %w(AbfWorker::IsoWorkerObserver AbfWorker::PublishObserver AbfWorker::RpmWorkerObserver)
  QUEUES = %w(rpm_worker_observer)
  QUEUE_CLASSES = %w(AbfWorker::RpmWorkerObserver)

  before_filter :authenticate_user!

  def shift
    @build_list = BuildList.next_build(arch_ids, platform_ids) if current_user.system?
    if @build_list
      set_builder
    else
      build_lists = BuildList.scoped_to_arch(arch_ids).
        for_status([BuildList::BUILD_PENDING, BuildList::RERUN_TESTS]).
        oldest.order(:created_at).
        for_platform(platform_ids)

      ActiveRecord::Base.transaction do
        if current_user.system?
          @build_list ||= build_lists.external_nodes(:everything).first
        else
          @build_list   = build_lists.external_nodes(:owned).for_user(current_user).first
          @build_list ||= build_lists.external_nodes(:everything).
            accessible_by(current_ability, :everything).readonly(false).first
        end
        set_builder
      end
    end

    job = {
      worker_queue: @build_list.worker_queue_with_priority(false),
      worker_class: @build_list.worker_queue_class,
      :worker_args  => [@build_list.abf_worker_args]
    } if @build_list
    render json: { job: job }.to_json
  end

  def statistics
    if params[:uid].present?
      RpmBuildNode.create(
        id:           params[:uid],
        user_id:      current_user.id,
        system:       current_user.system?,
        worker_count: params[:worker_count],
        busy_workers: params[:busy_workers]
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
      platforms = params[:platforms].to_s.split(',')
      platforms.present? ? Platform.where(name: platforms).pluck(:id) : []
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
    @build_list.save
  end

end
