# -*- encoding : utf-8 -*-
module AbfWorker
  class BuildListsPublishTaskManager
    REDIS_MAIN_KEY = 'abf-worker::build-lists-publish-task-manager::'

    # LOCKED_REP_AND_PLATFORMS: ['save_to_repository_id-build_for_platform_id', ...]
    %w(RESIGN_REPOSITORIES 
       PROJECTS_FOR_CLEANUP
       LOCKED_PROJECTS_FOR_CLEANUP
       LOCKED_REPOSITORIES
       LOCKED_REP_AND_PLATFORMS
       LOCKED_BUILD_LISTS
       PACKAGES_FOR_CLEANUP
       REGENERATE_METADATA).each do |kind|
      const_set kind, "#{REDIS_MAIN_KEY}#{kind.downcase.gsub('_', '-')}"
    end

    def initialize
      @redis          = Resque.redis
      @workers_count  = APP_CONFIG['abf_worker']['publish_workers_count']
    end

    def run
      create_tasks_for_resign_repositories
      create_tasks_for_repository_regenerate_metadata
      create_tasks_for_build_rpms
    end

    class << self
      def destroy_project_from_repository(project, repository)
        if repository.platform.personal?
          Platform.main.each do |main_platform|
            redis.lpush PROJECTS_FOR_CLEANUP, "#{project.id}-#{repository.id}-#{main_platform.id}"
            gather_old_packages project.id, repository.id, main_platform.id
          end
        else
          redis.lpush PROJECTS_FOR_CLEANUP, "#{project.id}-#{repository.id}-#{repository.platform.id}"
          gather_old_packages project.id, repository.id, repository.platform.id
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

      def resign_repository(key_pair)
        redis.lpush RESIGN_REPOSITORIES, key_pair.repository_id
      end

      def repository_regenerate_metadata(repository, build_for_platform)
        key = "#{repository.id}-#{build_for_platform.id}"
        return false if Resque.redis.lrange(REGENERATE_METADATA, 0, -1).include? key
        redis.lpush REGENERATE_METADATA, key
      end

      def unlock_repository(repository_id)
        redis.lrem LOCKED_REPOSITORIES, 0, repository_id
      end

      def unlock_build_list(build_list)
        redis.lrem LOCKED_BUILD_LISTS, 0, build_list.id
      end

      def unlock_rep_and_platform(lock_str)
        redis.lrem LOCKED_REP_AND_PLATFORMS, 0, lock_str
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


        Resque.push(
          'publish_worker_default',
          'class' => 'AbfWorker::PublishWorkerDefault',
          'args' => [{
            :id                   => build_list.id,
            :arch                 => build_list.arch.name,
            :distrib_type         => distrib_type,
            :cmd_params           => cmd_params,
            :platform             => {:platform_path => platform_path},
            :repository           => {:id => build_list.save_to_repository_id},
            :type                 => :publish,
            :time_living          => 9600, # 160 min
            :packages             => packages,
            :old_packages         => packages_structure,
            :build_list_ids       => [build_list.id],
            :projects_for_cleanup => [],
            :extra                => {:create_container => true}
          }]
        )
      end

      def gather_old_packages(project_id, repository_id, platform_id)
        build_lists_for_cleanup = []
        Arch.pluck(:id).each do |arch_id|
          bl = BuildList.where(:project_id => project_id).
            where(:new_core => true, :status => BuildList::BUILD_PUBLISHED).
            where(:save_to_repository_id => repository_id).
            where(:build_for_platform_id => platform_id).
            where(:arch_id => arch_id).
            order(:updated_at).first
          build_lists_for_cleanup << bl if bl
        end

        old_packages  = packages_structure
        build_lists_for_cleanup.each do |bl|
          bl.last_published.includes(:packages).limit(2).each{ |old_bl|
            fill_packages(old_bl, old_packages, :fullname)
          }
        end

        redis.hset PACKAGES_FOR_CLEANUP, "#{project_id}-#{repository_id}-#{platform_id}", old_packages.to_json
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


    def locked_repositories
      @redis.lrange LOCKED_REPOSITORIES, 0, -1
    end

    def create_tasks_for_resign_repositories
      resign_repos = @redis.lrange RESIGN_REPOSITORIES, 0, -1

      Repository.where(:id => (resign_repos - locked_repositories)).each do |r|
        # Checks mirror sync status
        next if r.repo_lock_file_exists?
        @redis.lrem   RESIGN_REPOSITORIES, 0, r.id
        @redis.lpush  LOCKED_REPOSITORIES, r.id


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
            :arch           => 'x86_64',
            :distrib_type   => distrib_type,
            :cmd_params     => cmd_params,
            :platform       => {:platform_path => "#{r.platform.path}/repository"},
            :repository     => {:id => r.id},
            :type           => :resign,
            :skip_feedback  => true,
            :time_living    => 9600 # 160 min
          }]
        )
      end
    end

    def create_tasks_for_build_rpms
      available_repos = BuildList.
        select('MIN(updated_at) as min_updated_at, save_to_repository_id, build_for_platform_id').
        where(:new_core => true, :status => BuildList::BUILD_PUBLISH).
        group(:save_to_repository_id, :build_for_platform_id).
        order(:min_updated_at).
        limit(@workers_count * 2) # because some repos may be locked

      locked_rep = locked_repositories
      available_repos = available_repos.where('save_to_repository_id NOT IN (?)', locked_rep) unless locked_rep.empty?

      counter = 1

      # looks like:
      # ['save_to_repository_id-build_for_platform_id', ...]
      locked_rep_and_pl = @redis.lrange(LOCKED_REP_AND_PLATFORMS, 0, -1)

      for_cleanup = @redis.lrange(PROJECTS_FOR_CLEANUP, 0, -1).map do |key|
        pr, rep, pl = *key.split('-')
        if locked_rep.present? && locked_rep.include?(rep)
          nil
        else
          [rep.to_i, pl.to_i]
        end
      end.compact
      available_repos = available_repos.map{ |bl| [bl.save_to_repository_id, bl.build_for_platform_id] } | for_cleanup

      available_repos.each do |save_to_repository_id, build_for_platform_id|
        next if locked_rep_and_pl.include?("#{save_to_repository_id}-#{build_for_platform_id}")
        break if counter > @workers_count
        counter += 1 if create_rpm_build_task(save_to_repository_id, build_for_platform_id)
      end      
    end

    def create_rpm_build_task(save_to_repository_id, build_for_platform_id)
      projects_for_cleanup = @redis.lrange(PROJECTS_FOR_CLEANUP, 0, -1).
        select{ |k| k =~ /#{save_to_repository_id}\-#{build_for_platform_id}$/ }

      # We should not to publish new builds into repository
      # if project of builds has been removed from repository.
      BuildList.where(
        :project_id             => projects_for_cleanup.map{ |k| k.split('-')[0] }.uniq,
        :save_to_repository_id  => save_to_repository_id,
        :status                 => BuildList::BUILD_PUBLISH
      ).update_all(:status => BuildList::FAILED_PUBLISH)

      build_lists = BuildList.
        where(:new_core => true, :status => BuildList::BUILD_PUBLISH).
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

      bl = build_lists.first
      return false if !bl && old_packages[:sources].empty?

      save_to_repository  = Repository.find save_to_repository_id
      # Checks mirror sync status
      return false if save_to_repository.repo_lock_file_exists?
      
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
        'BUILD_FOR_PLATFORM'  => build_for_platform.name
      }.map{ |k, v| "#{k}=#{v}" }.join(' ')

      lock_str  = "#{save_to_repository_id}-#{build_for_platform_id}"
      options   = {
        :id           => (bl ? bl.id : Time.now.to_i),
        :arch         => (bl ? bl.arch.name : 'x86_64'),
        :distrib_type => distrib_type,
        :cmd_params   => cmd_params,
        :platform     => {:platform_path => platform_path},
        :repository   => {:id => save_to_repository_id},
        :type         => :publish,
        :time_living  => 9600, # 160 min
        :extra        => {:lock_str => lock_str}
      }

      packages, build_list_ids, new_sources = self.class.packages_structure, [], {}
      build_lists.each do |bl|
        # remove duplicates of sources for different arches
        bl.packages.by_package_type('source').each{ |s| new_sources["#{s.fullname}"] = s.sha1 }
        self.class.fill_packages(bl, packages)
        bl.last_published.includes(:packages).limit(2).each{ |old_bl|
          self.class.fill_packages(old_bl, old_packages, :fullname)
        }
        build_list_ids << bl.id
        @redis.lpush(LOCKED_BUILD_LISTS, bl.id)
      end
      packages[:sources] = new_sources.values.compact

      Resque.push(
        worker_queue,
        'class' => worker_class,
        'args' => [options.merge({
          :packages => packages,
          :old_packages => old_packages,
          :build_list_ids => build_list_ids,
          :projects_for_cleanup => projects_for_cleanup
        })]
      )

      projects_for_cleanup.each do |key|
        @redis.lpush LOCKED_PROJECTS_FOR_CLEANUP, key
      end

      @redis.lpush(LOCKED_REP_AND_PLATFORMS, lock_str)
      return true
    end

    def create_tasks_for_repository_regenerate_metadata
      worker_queue        = 'publish_worker_default'
      worker_class        = 'AbfWorker::PublishWorkerDefault'
      regen_repos_and_pl  = @redis.lrange REGENERATE_METADATA, 0, -1
      locked_rep_and_pl   = @redis.lrange(LOCKED_REP_AND_PLATFORMS, 0, -1)

      regen_repos = regen_repos_and_pl.map{ |r| r.gsub(/\-[\d]*$/, '') }
      Repository.where(:id => regen_repos).each do |rep|
        # Checks mirror sync status
        next if rep.repo_lock_file_exists?
        regen_repos_and_pl.select{ |kind| kind =~ /^#{rep.id}\-/ }.each do |lock_str|
          next if locked_rep_and_pl.include?(lock_str)
          @redis.lrem REGENERATE_METADATA, 0, lock_str

          build_for_platform  = Platform.find lock_str.gsub(/^[\d]*\-/, '')
          cmd_params          = {
            'RELEASED'            => rep.platform.released,
            'REPOSITORY_NAME'     => rep.name,
            'TYPE'                => build_for_platform.distrib_type,
            'REGENERATE_METADATA' => true,
            'SAVE_TO_PLATFORM'    => rep.platform.name,
            'BUILD_FOR_PLATFORM'  => build_for_platform.name
          }.map{ |k, v| "#{k}=#{v}" }.join(' ')

          options = {
            :id           => Time.now.to_i,
            :arch         => 'x86_64',
            :distrib_type => build_for_platform.distrib_type,
            :cmd_params   => cmd_params,
            :platform     => {:platform_path => "#{rep.platform.path}/repository"},
            :repository   => {:id => rep.id},
            :type         => :publish,
            :time_living  => 9600, # 160 min
            :skip_feedback => true,
            :extra         => {:lock_str => lock_str, :regenerate => true}
          }

          Resque.push(
            worker_queue,
            'class' => worker_class,
            'args' => [options.merge({
            })]
          )

          @redis.lpush(LOCKED_REP_AND_PLATFORMS, lock_str)
        end
      end
      return true
    end
  end
end
