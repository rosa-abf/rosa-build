class ClearStaleBuildersJob
  @queue = :low

  def self.perform
    BuildList.where("updated_at < ?", 300.seconds.ago).
      where(status: [BuildList::BUILD_PENDING, BuildList::RERUN_TESTS]).
      where.not(builder: nil).update_all('builder_id = NULL')
  end
end