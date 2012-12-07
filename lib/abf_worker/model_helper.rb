module AbfWorker
  module ModelHelper
    # In model which contains this helper should be:
    # - #abf_worker_args
    # - #build_canceled

    def abf_worker_log
      q = 'abfworker::'
      q << worker_queue('-')
      q << '-'
      q << id.to_s
      Resque.redis.get(q) || I18n.t('layout.build_lists.log.not_available')
    end

    def add_job_to_abf_worker_queue
      Resque.push(
        worker_queue,
        'class' => worker_queue_class,
        'args' => [abf_worker_args]
      )
    end

    def cancel_job
      deleted = Resque::Job.destroy(
        worker_queue,
        worker_queue_class,
        abf_worker_args
      )
      if deleted == 1
        build_canceled
      else
        send_stop_signal
      end
      true
    end

    private

    def send_stop_signal
      Resque.redis.setex(
        live_inspector_queue,
        240,    # Data will be removed from Redis after 240 sec.
        'USR1'  # Immediately kill child but don't exit
      )
    end

    def live_inspector_queue
      q = 'abfworker::'
      q << worker_queue('-')
      q << '-'
      q << id.to_s
      q << '::live-inspector'
      q
    end

    def worker_queue(delimiter = '_')
      a = []
      a << (is_a?(BuildList) ? 'rpm' : 'iso')
      a << 'worker'
      a.join(delimiter)
    end

    def worker_queue_class
      is_a?(BuildList) ? 'AbfWorker::RpmWorker' : 'AbfWorker::IsoWorker'
    end

  end
end