# frozen_string_literal: true

class ChainBuildService::Groups
  attr_reader :chain_build, :arch_id

  def initialize(chain_build, arch_id)
    @chain_build = chain_build
    @arch_id = arch_id
  end

  def call
    res = []

    (0..chain_build.current_level).each do |level|
      res << {
        level: level+1,
        build_lists: chain_build.level_arch(level, arch_id).order(id: :asc)
      }
    end

    res
  end
end