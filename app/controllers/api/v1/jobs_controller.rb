# -*- encoding : utf-8 -*-
class Api::V1::JobsController < Api::V1::BaseController
  QUEUES = %w(iso_worker_observer publish_observer rpm_worker_observer)
  QUEUE_CLASSES = %w(AbfWorker::IsoWorkerObserver AbfWorker::PublishObserver AbfWorker::RpmWorkerObserver)

  before_filter :authenticate_user!

  def shift
    if current_user.system?
      queues = params[:worker_queues].split(',')
    else
      queues = BuildList.queues_for current_user
    end

    if queue = queues.find{ |q| job = Resque.redis.lpop "queue:#{q}" }
      job = JSON.parse job
      render :json => {
        :job => {
          :worker_queue => queue,
          :worker_class => job['class'],
          :worker_args  => job['args']
        }
      }.to_json
    else
      render :nothing => true
    end
  end

  def status
    render :text => Resque.redis.get(params[:key])
  end

  def feedback
    worker_queue = params[:worker_queue]
    worker_class = params[:worker_class]
    if QUEUES.include?(worker_queue) && QUEUE_CLASSES.include?(worker_class)
      Resque.push worker_queue, 'class' => worker_class, 'args'  => params[:worker_args]
      render :nothing => true
    else
      render :nothing => true, :status => 403
    end
  end

end
