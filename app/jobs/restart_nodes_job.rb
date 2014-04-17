class RestartNodesJob
  @queue = :low

  def self.perform
    return if NodeInstruction.all_locked?
    available_nodes = RpmBuildNode.all.map{ |n| n.user_id if n.user.try(:system?) }.compact.uniq
    NodeInstruction.where(status: NodeInstruction::READY).
      where.not(user_id: available_nodes).find_each(&:restart)
  end

end
