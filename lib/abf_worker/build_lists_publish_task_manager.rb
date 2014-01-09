# -*- encoding : utf-8 -*-
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
      @redis          = Resque.redis
      @workers_count  = APP_CONFIG['abf_worker']['publish_workers_count']
    end

    def run
      create_tasks_for_regenerate_metadata_for_software_center
      create_tasks_for_resign_repositories
      create_tasks_for_repository_regenerate_metadata
      create_tasks_for_build_rpms
      create_tasks_for_build_rpms true
    end

    class << self
      def destroy_project_from_repository(project, repository)
        if repository.platform.personal?
          Platform.main.each do |main_platform|
            key = "#{project.id}-#{repository.id}-#{main_platform.id}"
            redis.lpush PROJECTS_FOR_CLEANUP, key
            gather_old_packages project.id, repository.id, main_platform.id

            redis.lpush PROJECTS_FOR_CLEANUP, ('testing-' << key)
            gather_old_packages project.id, repository.id, main_platform.id, true
          end
        else
          key = "#{project.id}-#{repository.id}-#{repository.platform.id}"
          redis.lpush PROJECTS_FOR_CLEANUP, key
          gather_old_packages project.id, repository.id, repository.platform.id

          redis.lpush PROJECTS_FOR_CLEANUP, ('testing-' << key)
          gather_old_packages project.id, repository.id, repository.platform.id, true
        end
      end

      def cleanup_completed(projects_for_cleanup)
        projects_for_cleanup.each do |key|
          redis.lrem LOCKED_PROJECTS_FOR_CLEANUP, 0, key
          redis.hdel PACKAGES_FOR_CLEANUP, key
        end
      end

      def cleanup_failed(projects_for_cleanup)
        projects_for_cleanup.each do |key|
          redis.lrem LOCKED_PROJECTS_FOR_CLEANUP, 0, key
          redis.lpush PROJECTS_FOR_CLEANUP, key
        end
      end

      def cleanup_packages_from_testing(platform_id, repository_id, *build_lists)
        return if build_lists.blank?
        key = "#{BUILD_LISTS_FOR_CLEANUP_FROM_TESTING}-#{repository_id}-#{platform_id}"
        redis.lpush REP_AND_PLS_OF_BUILD_LISTS_FOR_CLEANUP_FROM_TESTING, "#{repository_id}-#{platform_id}"
        redis.lpush key, build_lists
      end

      def unlock_build_list(build_list)
        redis.lrem LOCKED_BUILD_LISTS, 0, build_list.id
      end

      def packages_structure
        structure = {:sources => [], :binaries => {}}
        Arch.pluck(:name).each{ |name| structure[:binaries][name.to_sym] = [] }
        structure
      end

      def redis
        Resque.redis
      end

      def create_container_for(build_list)
        platform_path = "#{build_list.save_to_platform.path}/container/#{build_list.id}"
        system "rm -rf #{platform_path} && mkdir -p #{platform_path}"

        packages = packages_structure
        packages[:sources] = build_list.packages.by_package_type('source').pluck(:sha1).compact
        packages[:binaries][build_list.arch.name.to_sym] = build_list.packages.by_package_type('binary').pluck(:sha1).compact

        distrib_type  = build_list.build_for_platform.distrib_type
        cmd_params    = {
          'RELEASED'            => false,
          'REPOSITORY_NAME'     => build_list.save_to_repository.name,
          'TYPE'                => distrib_type,
          'IS_CONTAINER'        => true,
          'ID'                  => build_list.id,
          'SAVE_TO_PLATFORM'    => build_list.save_to_platform.name,
          'BUILD_FOR_PLATFORM'  => build_list.build_for_platform.name
        }.map{ |k, v| "#{k}=#{v}" }.join(' ')

        # Low priority
        Resque.push(
          'publish_worker',
          'class' => 'AbfWorker::PublishWorker',
          'args' => [{
            :id                   => build_list.id,
            :cmd_params           => cmd_params,
            :main_script          => 'build.sh',
            :rollback_script      => 'rollback.sh',
            :platform             => {
              :platform_path  => platform_path,
              :type           => distrib_type,
              :name           => build_list.build_for_platform.name,
              :arch           => build_list.arch.name
            },
            :repository           => {:id => build_list.save_to_repository_id},
            :time_living          => 9600, # 160 min
            :packages             => packages,
            :old_packages         => packages_structure,
            :build_list_ids       => [build_list.id],
            :projects_for_cleanup => [],
            :extra                => {:create_container => true}
          }]
        )
      end

      def gather_old_packages(project_id, repository_id, platform_id, testing = false)
        build_lists_for_cleanup = []
        status = testing ? BuildList::BUILD_PUBLISHED_INTO_TESTING : BuildList::BUILD_PUBLISHED
        Arch.pluck(:id).each do |arch_id|
          bl = BuildList.where(:project_id => project_id).
            where(:new_core => true, :status => status).
            where(:save_to_repository_id => repository_id).
            where(:build_for_platform_id => platform_id).
            where(:arch_id => arch_id).
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
        redis.hset PACKAGES_FOR_CLEANUP, key, old_packages.to_json
      end

      def fill_packages(bl, results_map, field = :sha1)
        results_map[:sources] |= bl.packages.by_package_type('source').pluck(field).compact if field != :sha1
        
        binaries  = bl.packages.by_package_type('binary').pluck(field).compact
        arch      = bl.arch.name.to_sym
        results_map[:binaries][arch] |= binaries
        # Publish/remove i686 RHEL packages into/from x86_64
        if arch == :i586 && bl.build_for_platform.distrib_type == 'rhel' && bl.project.publish_i686_into_x86_64?
          results_map[:binaries][:x86_64] |= binaries
        end
      end

    end

    private

    def create_tasks_for_resign_repositories
      RepositoryStatus.platform_ready
                      .for_resign
                      .includes(:repository => :platform)
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
            :id             => r.id,
            :cmd_params     => cmd_params,
            :main_script    => 'resign.sh',
            :platform       => {
              :platform_path  => "#{r.platform.path}/repository",
              :type           => distrib_type,
              :name           => r.platform.name,
              :arch           => 'x86_64'
            },
            :repository     => {:id => r.id},
            :skip_feedback  => true,
            :time_living    => 9600, # 160 min
            :extra          => {:repository_status_id => repository_status.id, :resign => true}
          }]
        ) if repository_status.start_resign
      end
    end

    def create_tasks_for_build_rpms(testing = false)
      available_repos = BuildList.
        select('MIN(updated_at) as min_updated_at, save_to_repository_id, build_for_platform_id').
        where(:new_core => true, :status => (testing ? BuildList::BUILD_PUBLISH_INTO_TESTING : BuildList::BUILD_PUBLISH)).
        group(:save_to_repository_id, :build_for_platform_id).
        order(:min_updated_at).
        limit(@workers_count * 2) # because some repos may be locked

      locked_rep = RepositoryStatus.not_ready.joins(:platform).
        where(:platforms => {:platform_type => 'main'}).pluck(:repository_id)
      available_repos = available_repos.where('save_to_repository_id NOT IN (?)', locked_rep) unless locked_rep.empty?

      for_cleanup = @redis.lrange(PROJECTS_FOR_CLEANUP, 0, -1).map do |key|
        next if testing && key !~ /^testing-/
        rep, pl = *key.split('-').last(2)
        locked_rep.present? && locked_rep.include?(rep.to_i) ? nil : [rep.to_i, pl.to_i]
      end.compact

      for_cleanup_from_testing = @redis.lrange(REP_AND_PLS_OF_BUILD_LISTS_FOR_CLEANUP_FROM_TESTING, 0, -1).map do |key|
        next if redis.llen("#{BUILD_LISTS_FOR_CLEANUP_FROM_TESTING}-#{key}") == 0
        rep, pl = *key.split('-')
        locked_rep.present? && locked_rep.include?(rep.to_i) ? nil : [rep.to_i, pl.to_i]
      end.compact if testing
      for_cleanup_from_testing ||= []

      counter = 1
      available_repos = available_repos.map{ |bl| [bl.save_to_repository_id, bl.build_for_platform_id] } | for_cleanup | for_cleanup_from_testing
      available_repos.each do |save_to_repository_id, build_for_platform_id|
        next if RepositoryStatus.not_ready.where(:repository_id => save_to_repository_id, :platform_id => build_for_platform_id).exists?
        break if counter > @workers_count
        counter += 1 if create_rpm_build_task(save_to_repository_id, build_for_platform_id, testing)
      end      
    end

    def create_rpm_build_task(save_to_repository_id, build_for_platform_id, testing)
      key = "#{save_to_repository_id}-#{build_for_platform_id}"
      projects_for_cleanup = @redis.lrange(PROJECTS_FOR_CLEANUP, 0, -1).select do |k|
        (testing && k =~ /^testing-[\d]+-#{key}$/) || (!testing && k =~ /^[\d]+-#{key}$/)
      end

      # We should not to publish new builds into repository
      # if project of builds has been removed from repository.
      BuildList.where(
        :project_id             => projects_for_cleanup.map{ |k| k.split('-')[testing ? 1 : 0] }.uniq,
        :save_to_repository_id  => save_to_repository_id,
        :status                 => [BuildList::BUILD_PUBLISH, BuildList::BUILD_PUBLISH_INTO_TESTING]
      ).update_all(:status => BuildList::FAILED_PUBLISH)

      build_lists = BuildList.
        where(:new_core => true, :status => (testing ? BuildList::BUILD_PUBLISH_INTO_TESTING : BuildList::BUILD_PUBLISH)).
        where(:save_to_repository_id => save_to_repository_id).
        where(:build_for_platform_id => build_for_platform_id).
        order(:updated_at)
      locked_ids = @redis.lrange(LOCKED_BUILD_LISTS, 0, -1)
      build_lists = build_lists.where('build_lists.id NOT IN (?)', locked_ids) unless locked_ids.empty?
      build_lists = build_lists.limit(150)

      old_packages  = self.class.packages_structure

      projects_for_cleanup.each do |key|
        @redis.lrem PROJECTS_FOR_CLEANUP, 0, key
        packages = @redis.hget PACKAGES_FOR_CLEANUP, key
        next unless packages
        packages = JSON.parse packages
        old_packages[:sources] |= packages['sources']
        Arch.pluck(:name).each do |arch|
          old_packages[:binaries][arch.to_sym] |= packages['binaries'][arch]
        end
      end

      if testing
        build_lists_for_cleanup_from_testing = @redis.lrange(
          "#{BUILD_LISTS_FOR_CLEANUP_FROM_TESTING}-#{save_to_repository_id}-#{build_for_platform_id}"
          0, -1
        )
        BuildList.where(:id => build_lists_for_cleanup_from_testing).each do |b|
          self.class.fill_packages(b, old_packages)
        end if build_lists_for_cleanup_from_testing.present?
      end
      build_lists_for_cleanup_from_testing ||= []


      bl = build_lists.first
      return false if !bl && old_packages[:sources].empty?

      save_to_repository  = Repository.find save_to_repository_id
      # Checks mirror sync status
      return false if save_to_repository.repo_lock_file_exists? || !save_to_repository.platform.ready?

      repository_status = save_to_repository.repository_statuses.find_or_create_by_platform_id(build_for_platform_id)
      return false unless repository_status.publish
      
      save_to_platform    = save_to_repository.platform
      build_for_platform  = Platform.find build_for_platform_id
      platform_path = "#{save_to_platform.path}/repository"
      if save_to_platform.personal?
        platform_path << '/' << build_for_platform.name
        system "mkdir -p #{platform_path}"
      end
      worker_queue = bl ? bl.worker_queue_with_priority("publish_worker") : 'publish_worker_default'
      worker_class = bl ? bl.worker_queue_class("AbfWorker::PublishWorker") : 'AbfWorker::PublishWorkerDefault'

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
        :id               => (bl ? bl.id : Time.now.to_i),
        :cmd_params       => cmd_params,
        :main_script      => 'build.sh',
        :rollback_script  => 'rollback.sh',
        :platform     => {
          :platform_path  => platform_path,
          :type           => distrib_type,
          :name           => build_for_platform.name,
          :arch           => (bl ? bl.arch.name : 'x86_64')
        },
        :repository   => {:id => save_to_repository_id},
        :time_living  => 9600, # 160 min
        :extra        => {
          :repository_status_id => repository_status.id,
          :build_lists_for_cleanup_from_testing => build_lists_for_cleanup_from_testing
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
        @redis.lpush(LOCKED_BUILD_LISTS, bl.id)
      end
      packages[:sources] = new_sources.values.compact

      Resque.push(
        worker_queue,
        'class' => worker_class,
        'args' => [options.merge({
          :packages             => packages,
          :old_packages         => old_packages,
          :build_list_ids       => build_list_ids,
          :projects_for_cleanup => projects_for_cleanup
        })]
      )

      projects_for_cleanup.each do |key|
        @redis.lpush LOCKED_PROJECTS_FOR_CLEANUP, key
      end

      build_lists_for_cleanup_from_testing.each do |key|
        @redis.lrem "#{BUILD_LISTS_FOR_CLEANUP_FROM_TESTING}-#{save_to_repository_id}-#{build_for_platform_id}", 0, key
      end

      return true
    end

    def create_tasks_for_regenerate_metadata_for_software_center
      Platform.main.waiting_for_regeneration.each do |platform|
        repos = platform.repositories
        statuses = RepositoryStatus.where(:platform_id => platform.id)
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
            :id               => Time.now.to_i,
            :cmd_params       => cmd_params,
            :main_script      => 'regenerate_platform_metadata.sh',
            :platform     => {
              :platform_path  => "#{platform.path}/repository",
              :type           => platform.distrib_type,
              :name           => platform.name,
              :arch           => 'x86_64'
            },
            :time_living  => 9600, # 160 min
            :extra         => {:platform_id => platform.id, :regenerate_platform => true}
          }]
        ) if platform.start_regeneration

      end
    end

    def create_tasks_for_repository_regenerate_metadata
      RepositoryStatus.platform_ready
                      .for_regeneration
                      .includes(:repository => :platform)
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
            :id               => Time.now.to_i,
            :cmd_params       => cmd_params,
            :main_script      => 'build.sh',
            :rollback_script  => 'rollback.sh',
            :platform     => {
              :platform_path  => platform_path,
              :type           => build_for_platform.distrib_type,
              :name           => build_for_platform.name,
              :arch           => 'x86_64'
            },
            :time_living  => 9600, # 160 min
            :extra         => {:repository_status_id => repository_status.id, :regenerate => true}
          }]
        ) if repository_status.start_regeneration
      end
    end
  end
end
