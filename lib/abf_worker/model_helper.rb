module AbfWorker::ModelHelper
  # In model which contains this helper should be:
  # - #abf_worker_args
  # - #build_canceled

  MASS_BUILDS_SET = 'abf-worker::mass-builds'
  USER_BUILDS_SET = 'abf-worker::user-builds'

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def log_server
      @log_server ||= Redis.new(
        host: APP_CONFIG['abf_worker']['log_server']['host'],
        port: APP_CONFIG['abf_worker']['log_server']['port']
      )
    end

    def self.next_build
      raise NotImplementedError
    end

  end

  def abf_worker_log
    self.class.log_server.get(service_queue) || I18n.t('layout.build_lists.log.not_available')
  end

  def add_job_to_abf_worker_queue
    update_build_sets
    Resque.push(
      worker_queue_with_priority,
      'class' => worker_queue_class,
      'args' => [abf_worker_args]
    )
  end

  def restart_job
    update_build_sets
    Resque.redis.lpush "queue:#{worker_queue_with_priority}",
      Resque.encode({'class' => worker_queue_class, 'args' => [abf_worker_args]})
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
    result = Resque::Job.destroy(
      worker_queue_with_priority,
      worker_queue_class,
      abf_worker_args
    )
    cleanup_build_sets
    result
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

  def cleanup_build_sets
    return unless is_a?(BuildList)
    queue = worker_queue_with_priority
    if Resque.redis.llen("queue:#{queue}") == 0
      key = mass_build_id ? MASS_BUILDS_SET : USER_BUILDS_SET
      Resque.redis.srem key, mass_build_id || user_id
      Resque.redis.del "queue:#{queue}"
      Resque.redis.srem 'queues', queue
    end
  end

  private


  def update_build_sets
    return unless is_a?(BuildList)

    key = mass_build_id ? MASS_BUILDS_SET : USER_BUILDS_SET
    Resque.redis.sadd key, mass_build_id || user_id
    Resque.redis.sadd 'queues', worker_queue_with_priority
  end


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