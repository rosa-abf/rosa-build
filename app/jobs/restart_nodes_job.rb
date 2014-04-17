class RestartNodesJob
  @queue = :low

  def self.perform
    return if NodeInstruction.all_locked?
    available_nodes = RpmBuildNode.all.map{ |n| n.user_id }.compact.uniq
    NodeInstruction.where(status: NodeInstruction::READY).
      where('user_id NOT IN (?)', available_nodes).find_each(&:restart)
  end

end
