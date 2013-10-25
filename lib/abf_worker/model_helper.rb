module AbfWorker::ModelHelper
  # In model which contains this helper should be:
  # - #abf_worker_args
  # - #build_canceled

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def log_server
      @log_server ||= Redis.new(
        :host => APP_CONFIG['abf_worker']['log_server']['host'],
        :port => APP_CONFIG['abf_worker']['log_server']['port']
      )
    end
  end

  def abf_worker_log
    self.class.log_server.get(service_queue) || I18n.t('layout.build_lists.log.not_available')
  end

  def add_job_to_abf_worker_queue
    Resque.push(
      worker_queue_with_priority,
      'class' => worker_queue_class,
      'args' => [abf_worker_args]
    )
  end

  def cancel_job
    if destroy_from_resque_queue == 1
      build_canceled
    else
      send_stop_signal
    end
    true
  end

  def destroy_from_resque_queue
    Resque::Job.destroy(
      worker_queue_with_priority,
      worker_queue_class,
      abf_worker_args
    )
  end

  def worker_queue_with_priority(queue = nil)
    queue ||= abf_worker_base_queue
    queue << '_' << abf_worker_priority if abf_worker_priority.present?
    queue
  end

  def worker_queue_class(queue_class = nil)
    queue_class ||= "AbfWorker::#{abf_worker_base_queue.classify}"
    queue_class << abf_worker_priority.capitalize
  end

  private

  def send_stop_signal
    Resque.redis.setex(
      "#{service_queue}::live-inspector",
      240,    # Data will be removed from Redis after 240 sec.
      'USR1'  # Immediately kill child but don't exit
    )
  end

  def service_queue
    "abfworker::#{abf_worker_base_queue.gsub(/\_/, '-')}-#{id}"
  end

end