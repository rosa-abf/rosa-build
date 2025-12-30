# frozen_string_literal: true

class ChainBuildService::AddBuildList
  attr_reader :chain_build, :build_list, :new_level

  def initialize(chain_build, build_list, new_level)
    @chain_build = chain_build
    @build_list = build_list
    @new_level = new_level
  end

  def call
    if new_level
      start_new_level
    else
      continue_current_level
    end

    chain_build
  end

  private

  def start_new_level
    current = chain_build.current_level
    extra_build_lists = chain_build.level_arch(current, build_list.arch_id).pluck(:id)
    build_list.chain_build = chain_build
    build_list.level = current + 1
    build_list.first_in_chain = false
    build_list.extra_build_lists = extra_build_lists
  end

  def continue_current_level
    current = chain_build.current_level
    extra_build_lists =
      if current.zero?
        []
      else
        chain_build.level_arch(current - 1, build_list.arch_id).pluck(:id)
      end

    build_list.chain_build = chain_build
    build_list.level = current
    build_list.first_in_chain = false
    build_list.extra_build_lists = extra_build_lists
  end
end