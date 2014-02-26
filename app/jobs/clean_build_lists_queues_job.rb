class CleanBuildListsQueuesJob
  @queue = :hook

  def self.perform
    redis = Resque.redis
    redis.smembers('queues').each do |key|
      next if key !~ /(user|mass)_build_/
      queue = "queue:#{key}"
      last_updated_at = BuildList.where(user_id: key.gsub(/[^\d]/, '')).
        order('updated_at DESC').limit(1).pluck(:updated_at).first
      last_updated_at += 5.minutes if last_updated_at
      if redis.llen(queue) == 0 && (!last_updated_at || last_updated_at < Time.zone.now)
        redis.multi do
          redis.watch queue
          redis.del queue
          redis.srem 'queues', key
        end
      end
    end
  end

end
