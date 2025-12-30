class AdvanceChainsJob
  @queue = :low

  def self.perform
    ChainBuild.advancable.find_each do |cb|
      ChainBuildService::Advance.new(cb).call
    end
  end
end