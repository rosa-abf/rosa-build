class ClearStaleBuildersJob
  @queue = :low

  def self.perform
    build_lists = BuildList.where("updated_at < ?", 300.seconds.ago).
      where(status: [BuildList::BUILD_PENDING, BuildList::RERUN_TESTS]).
      where.not(builder: nil)
    ids = build_lists.pluck(:id)
    if !ids.empty?
      ids.each do |id|
        Redis.current.srem('abf_worker:shifted_build_lists', id)
      end
      build_lists.update_all('builder_id = NULL')
    end
  end
end
