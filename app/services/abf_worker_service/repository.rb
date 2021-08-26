module AbfWorkerService
  class Repository < Base

    attr_accessor :repository

    def initialize(repository)
      @repository = repository
    end

    def destroy_project!(project)
      if repository.platform.personal?
        Platform.main.each do |main_platform|
          key = "#{project.id}-#{repository.id}-#{main_platform.id}"
          $redis.with { |r| r.lpush PROJECTS_FOR_CLEANUP, key }
          gather_old_packages project.id, repository.id, main_platform.id

          $redis.with { |r| r.lpush PROJECTS_FOR_CLEANUP, ('testing-' << key) }
          gather_old_packages project.id, repository.id, main_platform.id, true
        end
      else
        key = "#{project.id}-#{repository.id}-#{repository.platform_id}"
        $redis.with { |r| r.lpush PROJECTS_FOR_CLEANUP, key }
        gather_old_packages project.id, repository.id, repository.platform_id

        $redis.with { |r| r.lpush PROJECTS_FOR_CLEANUP, ('testing-' << key) }
        gather_old_packages project.id, repository.id, repository.platform_id, true
      end
    end

    def resign!(repository_status)
      return if repository.repo_lock_file_exists?

      Resque.push(
        'publish_worker_default',
        'class' => "AbfWorker::PublishWorkerDefault",
        'args' => [{
          id:              repository.id,
          cmd_params:      cmd_params,
          main_script:     'resign.sh',
          platform:        {
            platform_path:   "#{repository.platform.path}/repository",
            type:            distrib_type,
            name:            repository.platform.name,
            arch:            'x86_64'
          },
          repository:      {id: repository.id},
          skip_feedback:   true,
          time_living:     9600, # 160 min
          extra:           {repository_status_id: repository_status.id, resign: true}
        }]
      ) if repository_status.start_resign
    end

    protected

    def cmd_params
      {
        'RELEASED'        => repository.platform.released,
        'REPOSITORY_NAME' => repository.name,
        'TYPE'            => distrib_type,
        'FILE_STORE_ADDR' => APP_CONFIG['file_store_url']
      }.map{ |k, v| "#{k}=#{v}" }.join(' ')
    end

    def distrib_type
      @distrib_type ||= repository.platform.distrib_type
    end

    def gather_old_packages(project_id, repository_id, platform_id, testing = false)
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
        bl.last_published(testing).includes(:packages).limit(2).each do |old_bl|
          fill_packages(old_bl, old_packages, :fullname)
        end
      end
      key = (testing ? 'testing-' : '') << "#{project_id}-#{repository_id}-#{platform_id}"
      $redis.with { |r| r.hset PACKAGES_FOR_CLEANUP, key, old_packages.to_json }
    end

  end
end
