class DestroyProjectFromRepositoryJob
  @queue = :middle

  include AbfWorkerHelper

  def self.perform(project_id, repository_id)
    project     = Project.find(project_id)
    repository  = Repository.find(repository_id)

    if repository.platform.personal?
      Platform.main.each do |main_platform|
        key = "#{project.id}-#{repository.id}-#{main_platform.id}"
        Redis.current.lpush PROJECTS_FOR_CLEANUP, key
        gather_old_packages project.id, repository.id, main_platform.id

        Redis.current.lpush PROJECTS_FOR_CLEANUP, ('testing-' << key)
        gather_old_packages project.id, repository.id, main_platform.id, true
      end
    else
      key = "#{project.id}-#{repository.id}-#{repository.platform.id}"
      Redis.current.lpush PROJECTS_FOR_CLEANUP, key
      gather_old_packages project.id, repository.id, repository.platform.id

      Redis.current.lpush PROJECTS_FOR_CLEANUP, ('testing-' << key)
      gather_old_packages project.id, repository.id, repository.platform.id, true
    end

  end

  def self.gather_old_packages(project_id, repository_id, platform_id, testing = false)
    build_lists_for_cleanup = []
    status = testing ? BuildList::BUILD_PUBLISHED_INTO_TESTING : BuildList::BUILD_PUBLISHED
    Arch.pluck(:id).each do |arch_id|
      bl = BuildList.where(project_id: project_id).
        where(new_core: true, status: status).
        where(save_to_repository_id: repository_id).
        where(build_for_platform_id: platform_id).
        where(arch_id: arch_id).
        order(:updated_at).first
      build_lists_for_cleanup << bl if bl
    end

    old_packages  = packages_structure
    build_lists_for_cleanup.each do |bl|
      bl.last_published(testing).includes(:packages).limit(2).each{ |old_bl|
        fill_packages(old_bl, old_packages, :fullname)
      }
    end
    key = (testing ? 'testing-' : '') << "#{project_id}-#{repository_id}-#{platform_id}"
    Redis.current.hset PACKAGES_FOR_CLEANUP, key, old_packages.to_json
  end

end
