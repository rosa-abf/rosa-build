# frozen_string_literal: true

class BuildListService::Restart
  attr_reader :build_list, :status

  def initialize(build_list)
    @build_list = build_list
    @status =
      if build_list.chain_build
        BuildList::RESTARTING
      else
        BuildList::BUILD_PENDING
      end
  end

  def call
    return if build_list.status == BuildList::WAITING_FOR_RESPONSE

    unpublish if build_list.chain_build
    update_version
    clean_filestore
    clear_files_and_items
    destroy_container unless build_list.chain_build
    update_status
    restart_chains if build_list.chain_build

    build_list.save!
  end

  private

  def restart_chains
    BuildList.where(chain_build: build_list.chain_build, arch_id: build_list.arch_id)
             .where.not(status: [BuildList::WAITING_FOR_RESPONSE, BuildList::RESTARTING])
             .where('level > ?', build_list.level).find_each do |bl|
      BuildListService::Restart.new(bl).call
    end
  end

  def clean_filestore
    build_list.later_destroy_files_from_file_store(build_list.sha1_of_file_store_files) if Rails.env.production?
  end

  def clear_files_and_items
    build_list.packages.destroy_all
    build_list.items.destroy_all
    build_list.results = []
  end

  def unpublish
    AbfWorkerService::Container.new(build_list).unpublish!
  end

  def destroy_container
    build_list.destroy_container
  end

  def update_version
    build_list.commit_hash = ''
    build_list.set_commit_and_version
    build_list.save!
  end

  def update_status
    build_list.status = status
    build_list.builder_id = nil
    $redis.with { |r| r.srem('abf_worker:shifted_build_lists', build_list.id) }
  end
end
