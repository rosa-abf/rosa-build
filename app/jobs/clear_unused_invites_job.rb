class ClearUnusedInvitesJob
  @queue = :low

  def self.perform
    Invite.outdated.unused.destroy_all
  end
end