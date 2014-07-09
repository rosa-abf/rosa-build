class RunExtraMassBuildsJob
  @queue = :low

  def self.perform
    RunExtraMassBuildsJob.new.perform
  end

  def perform
    MassBuild.where(status: MassBuild::BUILD_PENDING).find_each do |mb|
      next if mb.extra_mass_builds.blank?
      emb = MassBuild.where(status: MassBuild::SUCCESS, id: mb.extra_mass_builds).to_a
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