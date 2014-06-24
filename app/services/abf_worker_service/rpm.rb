module AbfWorkerService
  class Rpm < Base

    WORKERS_COUNT = APP_CONFIG['abf_worker']['publish_workers_count']

    attr_accessor :save_to_repository_id, :build_for_platform_id, :testing

    def initialize(save_to_repository_id, build_for_platform_id, testing)
      @save_to_repository_id  = save_to_repository_id
      @build_for_platform_id  = build_for_platform_id
      @testing                = testing
    end

    def self.publish!
      build_rpms
      build_rpms(true)
    end

    def self.build_rpms(testing = false)
      available_repos = BuildList.
        select('MIN(updated_at) as min_updated_at, save_to_repository_id, build_for_platform_id').
        where(new_core: true, status: (testing ? BuildList::BUILD_PUBLISH_INTO_TESTING : BuildList::BUILD_PUBLISH)).
        group(:save_to_repository_id, :build_for_platform_id).
        order('min_updated_at ASC').
        limit(WORKERS_COUNT * 2) # because some repos may be locked

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
        break if counter > WORKERS_COUNT
        service = AbfWorkerService::Rpm.new(
          save_to_repository_id,
          build_for_platform_id,
          testing
        )
        counter += 1 if service.create
      end
    end

    def create
      key = "#{save_to_repository_id}-#{build_for_platform_id}"
      projects_for_cleanup = Redis.current.lrange(PROJECTS_FOR_CLEANUP, 0, -1).select do |k|
        (testing && k =~ /^testing-[\d]+-#{key}$/) || (!testing && k =~ /^[\d]+-#{key}$/)
      end

      prepare_build_lists(projects_for_cleanup)

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
          fill_packages(b, old_packages, :fullname)
        end if build_lists_for_cleanup_from_testing.present?
      end
      build_lists_for_cleanup_from_testing ||= []

      bl = build_lists[0]
      return false if !bl && old_packages[:sources].empty? && old_packages[:binaries].values.flatten.empty?

      # Checks mirror sync status
      return false if save_to_repository.repo_lock_file_exists? || !save_to_repository.platform.ready?

      repository_status = save_to_repository.repository_statuses.find_or_create_by(platform_id: build_for_platform_id)
      return false unless repository_status.publish

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

      packages, build_list_ids, new_sources = fill_in_packages
      push(options.merge({
        packages:             packages,
        old_packages:         old_packages,
        build_list_ids:       build_list_ids,
        projects_for_cleanup: projects_for_cleanup
      }))
      lock_projects(projects_for_cleanup)
      cleanup(build_lists_for_cleanup_from_testing)
      return true
    end

    protected

    def platform_path
      @platform_path ||= begin
        path = "#{save_to_platform.path}/repository"
        if save_to_platform.personal?
          path << '/' << build_for_platform.name
          system "mkdir -p #{path}"
        end
        path
      end
    end

    def cmd_params
      {
        'RELEASED'            => save_to_platform.released,
        'REPOSITORY_NAME'     => save_to_repository.name,
        'TYPE'                => distrib_type,
        'SAVE_TO_PLATFORM'    => save_to_platform.name,
        'BUILD_FOR_PLATFORM'  => build_for_platform.name,
        'TESTING'             => testing
      }.map{ |k, v| "#{k}=#{v}" }.join(' ')
    end

    def save_to_repository
      @save_to_repository ||= ::Repository.find(save_to_repository_id)
    end

    def save_to_platform
      @save_to_platform ||= save_to_repository.platform
    end

    def build_for_platform
      @build_for_platform ||= Platform.find(build_for_platform_id)
    end

    def distrib_type
      @distrib_type ||= build_for_platform.distrib_type
    end

    def old_packages
      @old_packages ||= packages_structure
    end

    def fill_in_packages
      packages, build_list_ids, new_sources = packages_structure, [], {}
      build_lists.each do |bl|
        # remove duplicates of sources for different arches
        bl.packages.by_package_type('source').each{ |s| new_sources["#{s.fullname}"] = s.sha1 }
        fill_packages(bl, packages)
        bl.last_published(testing).includes(:packages).limit(2).each{ |old_bl|
          fill_packages(old_bl, old_packages, :fullname)
        }
        # TODO: do more flexible
        # Removes old packages which already in the main repo
        bl.last_published(false).includes(:packages).limit(3).each{ |old_bl|
          fill_packages(old_bl, old_packages, :fullname)
        } if testing
        build_list_ids << bl.id
        Redis.current.lpush(LOCKED_BUILD_LISTS, bl.id)
      end
      packages[:sources] = new_sources.values.compact

      [packages, build_list_ids, new_sources]
    end

    def lock_projects(projects_for_cleanup)
      projects_for_cleanup.each do |key|
        Redis.current.lpush LOCKED_PROJECTS_FOR_CLEANUP, key
      end
    end

    def cleanup(build_lists_for_cleanup_from_testing)
      rep_pl = "#{save_to_repository_id}-#{build_for_platform_id}"
      r_key = "#{BUILD_LISTS_FOR_CLEANUP_FROM_TESTING}-#{rep_pl}"
      build_lists_for_cleanup_from_testing.each do |key|
        Redis.current.srem r_key, key
      end
      if Redis.current.scard(r_key) == 0
        Redis.current.srem REP_AND_PLS_OF_BUILD_LISTS_FOR_CLEANUP_FROM_TESTING, rep_pl
      end
    end

    def push(options)
      Resque.push(
        'publish_worker_default',
        'class' => 'AbfWorker::PublishWorkerDefault',
        'args'  => [options]
      )
    end

    def prepare_build_lists(projects_for_cleanup)
      # We should not to publish new builds into repository
      # if project of builds has been removed from repository.
      BuildList.where(
        project_id:            projects_for_cleanup.map{ |k| k.split('-')[testing ? 1 : 0] }.uniq,
        save_to_repository_id: save_to_repository_id,
        status:                [BuildList::BUILD_PUBLISH, BuildList::BUILD_PUBLISH_INTO_TESTING]
      ).update_all(status: BuildList::FAILED_PUBLISH)
    end

    def build_lists
      @build_lists ||= begin
        build_lists = BuildList.
          where(new_core: true, status: (testing ? BuildList::BUILD_PUBLISH_INTO_TESTING : BuildList::BUILD_PUBLISH)).
          where(save_to_repository_id: save_to_repository_id).
          where(build_for_platform_id: build_for_platform_id).
          order(:updated_at)
        locked_ids  = Redis.current.lrange(LOCKED_BUILD_LISTS, 0, -1)
        build_lists = build_lists.where('build_lists.id NOT IN (?)', locked_ids) if locked_ids.present?
        build_lists = build_lists.limit(150)
        filter_build_lists_without_packages(build_lists.to_a)
      end
    end

    def filter_build_lists_without_packages(build_lists)
      ids = []
      build_lists = build_lists.select do |build_list|
        sha1 = build_list.packages.pluck(:sha1).find do |sha1|
          !FileStoreService::File.new(sha1: sha1).exist?
        end
        if sha1.present?
          ids << build_list.id
          false
        else
          true
        end
      end

      BuildList.where(id: ids).update_all(status: BuildList::PACKAGES_FAIL)

      build_lists
    end

  end
end