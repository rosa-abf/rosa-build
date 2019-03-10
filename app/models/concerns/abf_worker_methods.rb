module AbfWorkerMethods
  extend ActiveSupport::Concern

  MASS_BUILDS_SET = 'abf-worker::mass-builds'
  USER_BUILDS_SET = 'abf-worker::user-builds'

  module ClassMethods
    def log_server
      @log_server ||= Redis.new(url: ENV['REDIS_URL'])
    end
  end

  def abf_worker_log
    (self.class.log_server.get(service_queue) || I18n.t('layout.build_lists.log.not_available')).truncate(40000)
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
    elsif
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

  def worker_queue_with_priority(prefix = true)
    queue = ''

    if prefix && is_a?(BuildList)
      if mass_build_id
        queue << "mass_build_#{mass_build_id}_"
      else
        queue << "user_build_#{user_id}_"
      end
    end

    queue << abf_worker_base_queue
    queue << '_' << abf_worker_priority if abf_worker_priority.present?
    queue
  end

  def worker_queue_class
    "AbfWorker::#{abf_worker_base_queue.classify}#{abf_worker_priority.capitalize}"
  end

  private

  def send_stop_signal
    Redis.current.setex(
      "#{service_queue}::live-inspector",
      240,    # Data will be removed from Redis after 240 sec.
      'USR1'  # Immediately kill child but don't exit
    )
  end

  def service_queue
    "abfworker::#{abf_worker_base_queue.gsub(/\_/, '-')}-#{id}"
  end


end
