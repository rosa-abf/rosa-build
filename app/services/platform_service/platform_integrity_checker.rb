# frozen_string_literal: true

class PlatformService::PlatformIntegrityChecker
  attr_reader :platform

  def initialize(platform)
    @platform = platform
  end

  def call
    arches = if platform.platform_arch_settings.exists?
               platform.platform_arch_settings.by_default.pluck(:arch_id)
             else
               Arch.pluck(:id)
             end

    result = {}
    platform.repositories.find_each do |repository|
      result.merge!(PlatformService::RepositoryIntegrityChecker.new(repository, arches).call)
    end

    result
  end
end
