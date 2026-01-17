# frozen_string_literal: true

class ChainBuildService::Create
  attr_reader :user, :build_list, :chain_build

  def initialize(user, build_list, chain_build = nil)
    @user = user
    @build_list = build_list
    @chain_build = chain_build
  end

  def call
    res =
      if chain_build
        chain_build
      else
        ChainBuild.create(
          user: user,
          platform: build_list.save_to_platform
        )
      end
    build_list.chain_build = res
    build_list.level = 0
    build_list.first_in_chain = true

    res
  end
end