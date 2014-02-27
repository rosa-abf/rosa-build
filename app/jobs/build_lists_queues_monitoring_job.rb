class BuildListsQueuesMonitoringJob
  @queue = :hook

  def self.perform
    redis.smembers('queues').each do |key|
      next if key !~ /(user|mass)_build_/

      queue = "queue:#{key}"
      id    = key.gsub(/[^\d]/, '')

      if redis.llen(queue) == 0
        if key =~ /^user/
          last_updated_at = BuildList.select(:updated_at).
            where(user_id: id).order('updated_at DESC').first
        else
          last_updated_at = MassBuild.select(:updated_at).where(id: 250).first
        end
        last_updated_at = last_updated_at.try(:updated_at)
        # cleans queue if no activity and tasks for this queue
        clean(key) if !last_updated_at || (last_updated_at + 5.minutes) < Time.zone.now
      else
        # ensures that user/mass-build in the set from which we select next jobs
        set_key = key =~ /^user/ ? BuildList::USER_BUILDS_SET : BuildList::MASS_BUILDS_SET
        redis.sadd set_key, id
      end
      
    end
  end

  def self.clean(key)
    queue = "queue:#{key}"
    redis.watch(queue) do
      if redis.llen(queue) == 0
        redis.multi do |multi|
          multi.del   queue
          multi.srem  'queues', key
        end
      else
        redis.unwatch
      end
    end
  end

  def self.redis
    @redis ||= Resque.redis
  end

end
