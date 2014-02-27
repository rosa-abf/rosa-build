class CleanRpmBuildNodeJob
  @queue = :hook

  def self.perform
    RpmBuildNode.all.each do |n|
      n.delete unless n.user_id
    end
  end

end
