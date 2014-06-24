module BuildLists
  class QueuesMonitoringJob
    @queue = :middle

    def self.perform
      Redis.current.smembers('resque:queues').each do |key|
        next if key !~ /(user|mass)_build_/

        queue = "resque:queue:#{key}"
        id    = key.gsub(/[^\d]/, '')

        if Redis.current.llen(queue) == 0
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
          Redis.current.sadd set_key, id
        end
        
      end
    end

    def self.clean(key)
      queue = "resque:queue:#{key}"
      # See [#watch]: https://github.com/redis/redis-rb/blob/master/lib/redis.rb#L2012
      Redis.current.watch(queue) do
        if Redis.current.llen(queue) == 0
          Redis.current.multi do |multi|
            multi.del   queue
            multi.srem  'resque:queues', key
          end
        else
          Redis.current.unwatch
        end
      end
    end

  end
end