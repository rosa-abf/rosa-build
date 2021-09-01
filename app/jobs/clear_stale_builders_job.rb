class ClearStaleBuildersJob
  @queue = :low

  def self.perform
    $redis.with do |r|
      job_shift_sem = Redis::Semaphore.new(:job_shift_lock, redis: r)
      job_shift_sem.lock do
        build_lists = BuildList.where("updated_at < ?", 720.seconds.ago).
          where(status: [BuildList::BUILD_PENDING, BuildList::RERUN_TESTS]).
          where.not(builder: nil)
        ids = build_lists.pluck(:id)
        build_lists.update_all(builder_id: nil)
        if !ids.empty?
          ids.each do |id|
            r.srem('abf_worker:shifted_build_lists', id)
          end
        end
      end
    end
  end
end
