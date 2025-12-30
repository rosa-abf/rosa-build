# frozen_string_literal: true

class ChainBuildService::Advance
  attr_reader :chain_build

  def initialize(chain_build)
    @chain_build = chain_build
  end

  def call
    return unless chain_build.build_lists.exists?(status: BuildList::WAITING_FOR_RESPONSE)

    chain_build.build_lists.where(status: BuildList::WAITING_FOR_RESPONSE).find_each do |bl|
      extra_build_lists = BuildList.where(id: bl.extra_build_lists)
      if extra_build_lists.find_each.all? { |x| x.container_status == BuildList::BUILD_PUBLISHED }
        bl.place_build
      end
    end

    nil
  end
end