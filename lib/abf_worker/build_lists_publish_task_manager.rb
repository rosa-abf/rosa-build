# -*- encoding : utf-8 -*-
module AbfWorker
  class BuildListsPublishTaskManager
    REDIS_MAIN_KEY = 'abf-worker::build-lists-publish-task-manager::'

    %w(RESIGN_REPOSITORIES 
       PROJECTS_FOR_CLEANUP
       LOCKED_PROJECTS_FOR_CLEANUP
       LOCKED_REPOSITORIES
       LOCKED_REP_AND_PLATFORMS
       LOCKED_BUILD_LISTS).each do |kind|
      const_set kind, "#{REDIS_MAIN_KEY}#{kind.downcase.gsub('_', '-')}"
    end

    def initialize
      @redis          = Resque.redis
      @workers_count  = APP_CONFIG['abf_worker']['publish_workers_count']
    end

    def run
      create_tasks_for_resign_repositories
      create_tasks_for_build_rpms
    end

    class << self
      def destroy_project_from_repository(project, repository)
        if repository.platform.personal?
          Platform.main.each do |main_platform|
            redis.lpush PROJECTS_FOR_CLEANUP, "#{project.id}-#{repository.id}-#{main_platform.id}"
          end
        else
          redis.lpush PROJECTS_FOR_CLEANUP, "#{project.id}-#{repository.id}-#{repository.platform.id}"
        end
      end

      def cleanup_completed(projects_for_cleanup)
        projects_for_cleanup.each do |key|
          redis.lrem LOCKED_PROJECTS_FOR_CLEANUP, 0, key
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

      def unlock_repository(repository_id)
        redis.lrem LOCKED_REPOSITORIES, 0, repository_id
      end

      def unlock_build_list(build_list)
        redis.lrem LOCKED_BUILD_LISTS, 0, build_list.id
      end

      def unlock_rep_and_platform(build_list)
        redis.lrem LOCKED_REP_AND_PLATFORMS, 0, "#{build_list.save_to_repository_id}-#{build_list.build_for_platform_id}"
      end

      def redis
        Resque.redis
      end

      def create_container_for(build_list)
        platform_path = "#{build_list.save_to_platform.path}/container/#{build_list.id}"
        return if File.directory?(platform_path)
        system "mkdir -p #{platform_path}"
        build_list.update_column(:container_path, '')


        packages = {:sources => [], :binaries => {:x86_64 => [], :i586 => []}}
        packages[:sources] = build_list.packages.by_package_type('source').pluck(:sha1).compact
        packages[:binaries][build_list.arch.name.to_sym] = build_list.packages.by_package_type('binary').pluck(:sha1).compact 
        Resque.push(
          'publish_worker_default',
          'class' => 'AbfWorker::PublishWorkerDefault',
          'args' => [{
            :id => build_list.id,
            :arch => build_list.arch.name,
            :distrib_type => build_list.build_for_platform.distrib_type,
            :platform => {
              :platform_path => platform_path,
              :released => false
            },
            :repository => {
              :name => build_list.save_to_repository.name,
              :id => build_list.save_to_repository.id
            },
            :type => :publish,
            :time_living => 9600, # 160 min
            :packages => packages,
            :old_packages => {:sources => [], :binaries => {:x86_64 => [], :i586 => []}},
            :build_list_ids => [build_list.id],
            :projects_for_cleanup => [],
            :extra => {:create_container => true}
          }]
        )
      end
    end

    private

    def locked_repositories
      @redis.lrange LOCKED_REPOSITORIES, 0, -1
    end

    def create_tasks_for_resign_repositories
      resign_repos = @redis.lrange RESIGN_REPOSITORIES, 0, -1

      Repository.where(:id => (resign_repos - locked_repositories)).each do |r|
        @redis.lrem   RESIGN_REPOSITORIES, 0, r.id
        @redis.lpush  LOCKED_REPOSITORIES, r.id
        Resque.push(
          'publish_worker_default',
          'class' => "AbfWorker::PublishWorkerDefault",
          'args' => [{
            :id => r.id,
            :arch => 'x86_64',
            :distrib_type => r.platform.distrib_type,
            :platform => {
              :platform_path => "#{r.platform.path}/repository",
              :released => r.platform.released
            },
            :repository => {
              :name => r.name,
              :id => r.id
            },
            :type => :resign,
            :skip_feedback => true,
            :time_living => 9600 # 160 min
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
      build_lists = BuildList.
        where(:new_core => true, :status => BuildList::BUILD_PUBLISH).
        where(:save_to_repository_id => save_to_repository_id).
        where(:build_for_platform_id => build_for_platform_id).
        order(:updated_at)
      locked_ids = @redis.lrange(LOCKED_BUILD_LISTS, 0, -1)
      build_lists = build_lists.where('build_lists.id NOT IN (?)', locked_ids) unless locked_ids.empty?

      projects_for_cleanup = @redis.lrange(PROJECTS_FOR_CLEANUP, 0, -1).
        select{ |k| k =~ /#{save_to_repository_id}\-#{build_for_platform_id}$/ }

      build_lists_for_cleanup = projects_for_cleanup.map do |key|
        pr, rep, pl = *key.split('-')
        bl = BuildList.where(:project_id => pr).
          where(:new_core => true, :status => BuildList::BUILD_PUBLISHED).
          where(:save_to_repository_id => save_to_repository_id).
          where(:build_for_platform_id => build_for_platform_id).
          order(:updated_at).first
        unless bl
          # No packages for removing
          @redis.lrem PROJECTS_FOR_CLEANUP, 0, key
        end
        bl
      end.compact

      bl = build_lists.first || build_lists_for_cleanup.first
      return false unless bl

      platform_path = "#{bl.save_to_platform.path}/repository"
      if bl.save_to_platform.personal?
        platform_path << '/' << bl.build_for_platform.name
        system "mkdir -p #{platform_path}"
      end
      worker_queue = bl.worker_queue_with_priority("publish_worker")
      worker_class = bl.worker_queue_class("AbfWorker::PublishWorker")

      options = {
        :id => bl.id,
        :arch => bl.arch.name,
        :distrib_type => bl.build_for_platform.distrib_type,
        :platform => {
          :platform_path => platform_path,
          :released => bl.save_to_platform.released
        },
        :repository => {
          :name => bl.save_to_repository.name,
          :id => bl.save_to_repository.id
        },
        :type => :publish,
        :time_living => 9600 # 160 min
      }

      packages      = {:sources => [], :binaries => {:x86_64 => [], :i586 => []}}
      old_packages  = {:sources => [], :binaries => {:x86_64 => [], :i586 => []}}
      build_list_ids = []

      new_sources = {}
      build_lists.each do |bl|
        # remove duplicates of sources for different arches
        bl.packages.by_package_type('source').each{ |s| new_sources["#{s.fullname}"] = s.sha1 }
        fill_packages(bl, packages)
        bl.last_published.includes(:packages).limit(5).each{ |old_bl|
          fill_packages(old_bl, old_packages, :fullname)
        }
        build_list_ids << bl.id
        @redis.lpush(LOCKED_BUILD_LISTS, bl.id)
      end
      packages[:sources] = new_sources.values.compact

      build_lists_for_cleanup.each do |bl|
        bl.last_published.includes(:packages).limit(5).each{ |old_bl|
          fill_packages(old_bl, old_packages, :fullname)
        }
      end

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
        @redis.lrem PROJECTS_FOR_CLEANUP, 0, key
        @redis.lpush LOCKED_PROJECTS_FOR_CLEANUP, key
      end

      @redis.lpush(LOCKED_REP_AND_PLATFORMS, "#{save_to_repository_id}-#{build_for_platform_id}")
      return true
    end

    def fill_packages(bl, results_map, field = :sha1)
      results_map[:sources] |= bl.packages.by_package_type('source').pluck(field).compact if field != :sha1
      results_map[:binaries][bl.arch.name.to_sym] |= bl.packages.by_package_type('binary').pluck(field).compact      
    end

  end
end