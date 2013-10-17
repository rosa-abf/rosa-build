# -*- encoding : utf-8 -*-
class Api::V1::JobsController < Api::V1::BaseController
  # QUEUES = %w(iso_worker_observer publish_observer rpm_worker_observer)
  # QUEUE_CLASSES = %w(AbfWorker::IsoWorkerObserver AbfWorker::PublishObserver AbfWorker::RpmWorkerObserver)
  QUEUES = %w(rpm_worker_observer)
  QUEUE_CLASSES = %w(AbfWorker::RpmWorkerObserver)

  before_filter :authenticate_user!

  def shift
    ActiveRecord::Base.transaction do
      build_lists = BuildList.for_status(BuildList::BUILD_PENDING).oldest.order(:create_at)
      if current_user.system?
        build_list = build_lists.not_owned_external_nodes.first

        build_list.touch if build_list
      else
        build_list = build_lists.external_nodes(:owned).for_user(current_user).first
        build_list ||= build_lists.external_nodes(:everything).
          accessible_by(current_ability, :everything).first

        if build_list
          build_list.builder = current_user
          build_list.save
        end
      end
    end

    if build_list
      job = {
        :worker_queue => build_list.worker_queue_with_priority,
        :worker_class => build_list.worker_queue_class,
        :worker_args  => [build_list.abf_worker_args]
      }
    end
    render :json => { :job => job }.to_json
  end

  def status
    render :text => Resque.redis.get(params[:key])
  end

  def feedback
    worker_queue = params[:worker_queue]
    worker_class = params[:worker_class]
    if  QUEUES.include?(worker_queue) && QUEUE_CLASSES.include?(worker_class)
      worker_args = (params[:worker_args] || []).first || {}
      worker_args = worker_args.merge(:feedback_from_user => current_user.id)
      Resque.push worker_queue, 'class' => worker_class, 'args'  => [worker_args]
      render :nothing => true
    else
      render :nothing => true, :status => 403
    end
  end

end
