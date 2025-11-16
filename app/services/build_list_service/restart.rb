# frozen_string_literal: true

class BuildListService::Restart
  attr_reader :build_list

  def initialize(build_list)
    @build_list = build_list
  end

  def call
    update_version
    clean_filestore
    clear_files_and_items
    unpublish_from_container
    update_status

    build_list.save!
  end

  private

  def clean_filestore
    build_list.later_destroy_files_from_file_store(build_list.sha1_of_file_store_files)
  end

  def clear_files_and_items
    build_list.packages.destroy_all
    build_list.items.destroy_all
    build_list.results = []
  end

  # TODO: fix for chain builds
  def unpublish_from_container
    build_list.destroy_container
  end

  def update_version
    build_list.set_commit_and_version
    build_list.save!
  end

  def update_status
    build_list.status = BuildList::BUILD_PENDING
    build_list.builder_id = nil
    $redis.with { |r| r.srem('abf_worker:shifted_build_lists', build_list.id) }
  end
end
