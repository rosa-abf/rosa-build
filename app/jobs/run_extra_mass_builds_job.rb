class RunExtraMassBuildsJob
  @queue = :low

  def self.perform
    RunExtraMassBuildsJob.new.perform
  end

  def perform
    MassBuild.where(status: BUILD_PENDING).find_each do |mb|
      next if mb.extra_mass_builds.blank?
      next if mb.extra_mass_builds.exclude?(mass_build_id)
      emb = MassBuild.where(status: SUCCESS, id: mb.extra_mass_builds).to_a
      next if emb.size != mb.extra_mass_builds.size

      next if emb.find{ |mb| not_ready?(mb) }
      mb.build_all
    end
  end

  private

  # Returns true if mass build has not published packages or packages without container
  def not_ready?(mb)
    mb.build_lists.count != mb.build_lists.where(
      'status = ? OR container_status = ?',
      BuildList::BUILD_PUBLISHED,
      BuildList::BUILD_PUBLISHED
    ).count
  end

end