# -*- encoding : utf-8 -*-
class Api::V1::JobsController < Api::V1::BaseController
  # QUEUES = %w(iso_worker_observer publish_observer rpm_worker_observer)
  # QUEUE_CLASSES = %w(AbfWorker::IsoWorkerObserver AbfWorker::PublishObserver AbfWorker::RpmWorkerObserver)
  QUEUES = %w(rpm_worker_observer)
  QUEUE_CLASSES = %w(AbfWorker::RpmWorkerObserver)

  before_filter :authenticate_user!

  def shift
    platform_ids = Platform.where(name: params[:platforms].split(',')).pluck(:id) if params[:platforms].present?
    arch_ids = Arch.where(name: params[:arches].split(',')).pluck(:id) if params[:arches].present?
    build_lists = BuildList.for_status(BuildList::BUILD_PENDING).scoped_to_arch(arch_ids).
      oldest.order(:created_at)
    build_lists = build_lists.for_platform(platform_ids) if platform_ids.present?

    if current_user.system?
      if task = (Resque.pop('rpm_worker_default') || Resque.pop('rpm_worker'))
        @build_list = BuildList.where(:id => task['args'][0]['id']).first
      end
    end

    ActiveRecord::Base.transaction do
      if current_user.system?
        @build_list ||= build_lists.external_nodes(:everything).first
        @build_list.touch if @build_list
      else
        @build_list = build_lists.external_nodes(:owned).for_user(current_user).first
        @build_list ||= build_lists.external_nodes(:everything).
          accessible_by(current_ability, :everything).readonly(false).first

        if @build_list
          @build_list.builder = current_user
          @build_list.save
        end
      end
    end unless @build_list

    if @build_list
      job = {
        :worker_queue => @build_list.worker_queue_with_priority,
        :worker_class => @build_list.worker_queue_class,
        :worker_args  => [@build_list.abf_worker_args]
      }
    end
    render :json => { :job => job }.to_json
  end

  def statistics
    if params[:uid].present?
      RpmBuildNode.create(
        :id           => params[:uid],
        :user_id      => current_user.id,
        :system       => current_user.system?,
        :worker_count => params[:worker_count],
        :busy_workers => params[:busy_workers]
      ) rescue nil
    end
    render :nothing => true
  end

  def status
    render :text => Resque.redis.get(params[:key])
  end

  def logs
    name = params[:name]
    if name =~ /abfworker::rpm-worker/
      if current_user.system? || current_user.id == BuildList.where(:id => name.gsub(/[^\d]/, '')).first.try(:builder_id)
        BuildList.log_server.setex name, 15, params[:logs]
      end
    end
    render :nothing => true
  end

  def feedback
    worker_queue = params[:worker_queue]
    worker_class = params[:worker_class]
    if QUEUES.include?(worker_queue) && QUEUE_CLASSES.include?(worker_class)
      worker_args = (params[:worker_args] || []).first || {}
      worker_args = worker_args.merge(:feedback_from_user => current_user.id)
      Resque.push worker_queue, 'class' => worker_class, 'args' => [worker_args]
      render :nothing => true
    else
      render :nothing => true, :status => 403
    end
  end

end
