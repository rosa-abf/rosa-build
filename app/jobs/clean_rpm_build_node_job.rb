class CleanRpmBuildNodeJob
  @queue = :middle

  def self.perform
    RpmBuildNode.cleanup
  end

end
