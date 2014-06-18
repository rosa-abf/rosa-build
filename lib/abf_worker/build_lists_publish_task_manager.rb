module AbfWorker
  class BuildListsPublishTaskManager
    REDIS_MAIN_KEY = 'abf-worker::build-lists-publish-task-manager::'

    %w(PROJECTS_FOR_CLEANUP
       LOCKED_PROJECTS_FOR_CLEANUP
       LOCKED_BUILD_LISTS
       PACKAGES_FOR_CLEANUP
       REP_AND_PLS_OF_BUILD_LISTS_FOR_CLEANUP_FROM_TESTING
       BUILD_LISTS_FOR_CLEANUP_FROM_TESTING).each do |kind|
      const_set kind, "#{REDIS_MAIN_KEY}#{kind.downcase.gsub('_', '-')}"
    end

    def initialize
      @workers_count = APP_CONFIG['abf_worker']['publish_workers_count']
    end

    def run
      create_tasks_for_regenerate_metadata_for_software_center
      create_tasks_for_resign_repositories
      create_tasks_for_repository_regenerate_metadata
      create_tasks_for_build_rpms
      create_tasks_for_build_rpms true
    end

    private

    def create_tasks_for_resign_repositories
      RepositoryStatus.platform_ready
                      .for_resign
                      .includes(repository: :platform)
                      .readonly(false)
                      .each do |repository_status|
        r = repository_status.repository
        # Checks mirror sync status
        next if r.repo_lock_file_exists?

        distrib_type  = r.platform.distrib_type
        cmd_params    = {
          'RELEASED'        => r.platform.released,
          'REPOSITORY_NAME' => r.name,
          'TYPE'            => distrib_type
        }.map{ |k, v| "#{k}=#{v}" }.join(' ')

        Resque.push(
          'publish_worker_default',
          'class' => "AbfWorker::PublishWorkerDefault",
          'args' => [{
            id:              r.id,
            cmd_params:      cmd_params,
            main_script:     'resign.sh',
            platform:        {
              platform_path:   "#{r.platform.path}/repository",
              type:            distrib_type,
              name:            r.platform.name,
              arch:            'x86_64'
            },
            repository:      {id: r.id},
            skip_feedback:   true,
            time_living:     9600, # 160 min
            extra:           {repository_status_id: repository_status.id, resign: true}
          }]
        ) if repository_status.start_resign
      end
    end

    def create_tasks_for_build_rpms(testing = false)
      available_repos = BuildList.
        select('MIN(updated_at) as min_updated_at, save_to_repository_id, build_for_platform_id').
        where(new_core: true, status: (testing ? BuildList::BUILD_PUBLISH_INTO_TESTING : BuildList::BUILD_PUBLISH)).
        group(:save_to_repository_id, :build_for_platform_id).
        order('min_updated_at ASC').
        limit(@workers_count * 2) # because some repos may be locked

      locked_rep = RepositoryStatus.not_ready.joins(:platform).
        where(platforms: {platform_type: 'main'}).pluck(:repository_id)
      available_repos = available_repos.where('save_to_repository_id NOT IN (?)', locked_rep) unless locked_rep.empty?

      for_cleanup = Redis.current.lrange(PROJECTS_FOR_CLEANUP, 0, -1).map do |key|
        next if testing && key !~ /^testing-/
        rep, pl = *key.split('-').last(2)
        locked_rep.present? && locked_rep.include?(rep.to_i) ? nil : [rep.to_i, pl.to_i]
      end.compact

      for_cleanup_from_testing = Redis.current.smembers(REP_AND_PLS_OF_BUILD_LISTS_FOR_CLEANUP_FROM_TESTING).map do |key|
        next if Redis.current.scard("#{BUILD_LISTS_FOR_CLEANUP_FROM_TESTING}-#{key}") == 0
        rep, pl = *key.split('-')
        locked_rep.present? && locked_rep.include?(rep.to_i) ? nil : [rep.to_i, pl.to_i]
      end.compact if testing
      for_cleanup_from_testing ||= []

      counter = 1
      available_repos = available_repos.map{ |bl| [bl.save_to_repository_id, bl.build_for_platform_id] } | for_cleanup | for_cleanup_from_testing
      available_repos.each do |save_to_repository_id, build_for_platform_id|
        next if RepositoryStatus.not_ready.where(repository_id: save_to_repository_id, platform_id: build_for_platform_id).exists?
        break if counter > @workers_count
        counter += 1 if create_rpm_build_task(save_to_repository_id, build_for_platform_id, testing)
      end
    end

    def create_rpm_build_task(save_to_repository_id, build_for_platform_id, testing)
      key = "#{save_to_repository_id}-#{build_for_platform_id}"
      projects_for_cleanup = Redis.current.lrange(PROJECTS_FOR_CLEANUP, 0, -1).select do |k|
        (testing && k =~ /^testing-[\d]+-#{key}$/) || (!testing && k =~ /^[\d]+-#{key}$/)
      end

      # We should not to publish new builds into repository
      # if project of builds has been removed from repository.
      BuildList.where(
        project_id:            projects_for_cleanup.map{ |k| k.split('-')[testing ? 1 : 0] }.uniq,
        save_to_repository_id: save_to_repository_id,
        status:                [BuildList::BUILD_PUBLISH, BuildList::BUILD_PUBLISH_INTO_TESTING]
      ).update_all(status: BuildList::FAILED_PUBLISH)

      build_lists = BuildList.
        where(new_core: true, status: (testing ? BuildList::BUILD_PUBLISH_INTO_TESTING : BuildList::BUILD_PUBLISH)).
        where(save_to_repository_id: save_to_repository_id).
        where(build_for_platform_id: build_for_platform_id).
        order(:updated_at)
      locked_ids = Redis.current.lrange(LOCKED_BUILD_LISTS, 0, -1)
      build_lists = build_lists.where('build_lists.id NOT IN (?)', locked_ids) unless locked_ids.empty?
      build_lists = build_lists.limit(150)

      old_packages  = self.class.packages_structure

      projects_for_cleanup.each do |key|
        Redis.current.lrem PROJECTS_FOR_CLEANUP, 0, key
        packages = Redis.current.hget PACKAGES_FOR_CLEANUP, key
        next unless packages
        packages = JSON.parse packages
        old_packages[:sources] |= packages['sources']
        Arch.pluck(:name).each do |arch|
          old_packages[:binaries][arch.to_sym] |= packages['binaries'][arch] || []
        end
      end

      if testing
        build_lists_for_cleanup_from_testing = Redis.current.smembers("#{BUILD_LISTS_FOR_CLEANUP_FROM_TESTING}-#{save_to_repository_id}-#{build_for_platform_id}")
        BuildList.where(id: build_lists_for_cleanup_from_testing).each do |b|
          self.class.fill_packages(b, old_packages, :fullname)
        end if build_lists_for_cleanup_from_testing.present?
      end
      build_lists_for_cleanup_from_testing ||= []

      bl = build_lists.first
      return false if !bl && old_packages[:sources].empty? && old_packages[:binaries].values.flatten.empty?

      save_to_repository  = Repository.find save_to_repository_id
      # Checks mirror sync status
      return false if save_to_repository.repo_lock_file_exists? || !save_to_repository.platform.ready?

      repository_status = save_to_repository.repository_statuses.find_or_create_by(platform_id: build_for_platform_id)
      return false unless repository_status.publish

      save_to_platform    = save_to_repository.platform
      build_for_platform  = Platform.find build_for_platform_id
      platform_path = "#{save_to_platform.path}/repository"
      if save_to_platform.personal?
        platform_path << '/' << build_for_platform.name
        system "mkdir -p #{platform_path}"
      end

      distrib_type  = build_for_platform.distrib_type
      cmd_params    = {
        'RELEASED'            => save_to_platform.released,
        'REPOSITORY_NAME'     => save_to_repository.name,
        'TYPE'                => distrib_type,
        'SAVE_TO_PLATFORM'    => save_to_platform.name,
        'BUILD_FOR_PLATFORM'  => build_for_platform.name,
        'TESTING'             => testing
      }.map{ |k, v| "#{k}=#{v}" }.join(' ')

      options   = {
        id:                (bl ? bl.id : Time.now.to_i),
        cmd_params:        cmd_params,
        main_script:       'build.sh',
        rollback_script:   'rollback.sh',
        platform:        {
          platform_path:   platform_path,
          type:            distrib_type,
          name:            build_for_platform.name,
          arch:            (bl ? bl.arch.name : 'x86_64')
        },
        repository:    {id: save_to_repository_id},
        time_living:   9600, # 160 min
        extra:         {
          repository_status_id: repository_status.id,
          build_lists_for_cleanup_from_testing: build_lists_for_cleanup_from_testing
        }
      }

      packages, build_list_ids, new_sources = self.class.packages_structure, [], {}
      build_lists.each do |bl|
        # remove duplicates of sources for different arches
        bl.packages.by_package_type('source').each{ |s| new_sources["#{s.fullname}"] = s.sha1 }
        self.class.fill_packages(bl, packages)
        bl.last_published(testing).includes(:packages).limit(2).each{ |old_bl|
          self.class.fill_packages(old_bl, old_packages, :fullname)
        }
        # TODO: do more flexible
        # Removes old packages which already in the main repo
        bl.last_published(false).includes(:packages).limit(3).each{ |old_bl|
          self.class.fill_packages(old_bl, old_packages, :fullname)
        } if testing
        build_list_ids << bl.id
        Redis.current.lpush(LOCKED_BUILD_LISTS, bl.id)
      end
      packages[:sources] = new_sources.values.compact

      Resque.push(
        'publish_worker_default',
        'class' => 'AbfWorker::PublishWorkerDefault',
        'args'  => [options.merge({
          packages:             packages,
          old_packages:         old_packages,
          build_list_ids:       build_list_ids,
          projects_for_cleanup: projects_for_cleanup
        })]
      )

      projects_for_cleanup.each do |key|
        Redis.current.lpush LOCKED_PROJECTS_FOR_CLEANUP, key
      end

      rep_pl = "#{save_to_repository_id}-#{build_for_platform_id}"
      r_key = "#{BUILD_LISTS_FOR_CLEANUP_FROM_TESTING}-#{rep_pl}"
      build_lists_for_cleanup_from_testing.each do |key|
        Redis.current.srem r_key, key
      end
      if Redis.current.scard(r_key) == 0
        Redis.current.srem REP_AND_PLS_OF_BUILD_LISTS_FOR_CLEANUP_FROM_TESTING, rep_pl
      end

      return true
    end

    def create_tasks_for_regenerate_metadata_for_software_center
      Platform.main.waiting_for_regeneration.each do |platform|
        repos = platform.repositories
        statuses = RepositoryStatus.where(platform_id: platform.id)
        next if repos.find{ |r| r.repo_lock_file_exists? }
        next if statuses.present? &&
          statuses.map{ |s| s.ready? || s.can_start_regeneration? || s.can_start_resign? }.uniq != [true]

        cmd_params          = {
          'RELEASED'            => platform.released,
          'REPOSITORY_NAMES'    => platform.repositories.map(&:name).join(','),
          'TYPE'                => platform.distrib_type,
          'REGENERATE_PLATFORM_METADATA' => true,
          'SAVE_TO_PLATFORM'    => platform.name,
          'BUILD_FOR_PLATFORM'  => platform.name
        }.map{ |k, v| "#{k}=#{v}" }.join(' ')

        Resque.push(
          'publish_worker_default',
          'class' => 'AbfWorker::PublishWorkerDefault',
          'args' => [{
            id:              Time.now.to_i,
            cmd_params:      cmd_params,
            main_script:     'regenerate_platform_metadata.sh',
            platform:        {
              platform_path:   "#{platform.path}/repository",
              type:            platform.distrib_type,
              name:            platform.name,
              arch:            'x86_64'
            },
            time_living:     9600, # 160 min
            extra:           {platform_id: platform.id, regenerate_platform: true}
          }]
        ) if platform.start_regeneration

      end
    end

    def create_tasks_for_repository_regenerate_metadata
      RepositoryStatus.platform_ready
                      .for_regeneration
                      .includes(repository: :platform)
                      .readonly(false)
                      .each do |repository_status|
        rep = repository_status.repository
        # Checks mirror sync status
        next if rep.repo_lock_file_exists?

        build_for_platform  = repository_status.platform
        cmd_params          = {
          'RELEASED'            => rep.platform.released,
          'REPOSITORY_NAME'     => rep.name,
          'TYPE'                => build_for_platform.distrib_type,
          'REGENERATE_METADATA' => true,
          'SAVE_TO_PLATFORM'    => rep.platform.name,
          'BUILD_FOR_PLATFORM'  => build_for_platform.name
        }.map{ |k, v| "#{k}=#{v}" }.join(' ')

        platform_path = "#{rep.platform.path}/repository"
        if rep.platform.personal?
          platform_path << '/' << build_for_platform.name
          system "mkdir -p #{platform_path}"
        end

        Resque.push(
          'publish_worker_default',
          'class' => 'AbfWorker::PublishWorkerDefault',
          'args' => [{
            id:              Time.now.to_i,
            cmd_params:      cmd_params,
            main_script:     'build.sh',
            rollback_script: 'rollback.sh',
            platform:        {
              platform_path:   platform_path,
              type:            build_for_platform.distrib_type,
              name:            build_for_platform.name,
              arch:            'x86_64'
            },
            repository:     {id: rep.id},
            # time_living:     9600, # 160 min
            time_living:    14400, # 240 min
            extra:          {repository_status_id: repository_status.id, regenerate: true}
          }]
        ) if repository_status.start_regeneration
      end
    end
  end
end
