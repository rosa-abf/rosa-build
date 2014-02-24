class CleanBuildListsQueuesJob
  @queue = :hook

  def self.perform
    redis = Resque.redis
    redis.smembers('queues').each do |key|
      next if key !~ /(user|mass)_build_/
      queue = "queue:#{key}"
      if redis.llen(queue) == 0
        redis.multi do
          redis.watch queue
          redis.del queue
          redis.srem 'queues', key
        end
      end
    end
  end

end
