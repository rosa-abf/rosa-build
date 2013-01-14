module AbfWorker
  class BuildListsPublishTaskManager
    REDIS_MAIN_KEY = 'abf-worker::build-lists-publish-task-manager::'
    LOCKED_REP_AND_PLATFORMS = "#{REDIS_MAIN_KEY}locked-repositories-and-platforms"
    LOCKED_BUILD_LISTS = "#{REDIS_MAIN_KEY}locked-build-lists"

    def initialize
      @redis          = Resque.redis
      @workers_count  = APP_CONFIG['abf_worker']['publish_workers_count']
    end

    def run
      available_repos = BuildList.
        select('MIN(updated_at) as min_updated_at, save_to_repository_id, build_for_platform_id').
        where(:new_core => true, :status => BuildList::BUILD_PUBLISH).
        group(:save_to_repository_id, :build_for_platform_id).
        order(:min_updated_at).
        limit(@workers_count * 2) # because some repos may be locked

      counter = 1

      # looks like:
      # ['save_to_repository_id-build_for_platform_id', ...]
      locked_rep_and_pl = @redis.lrange(LOCKED_REP_AND_PLATFORMS, 0, -1)
      available_repos.each do |el|
        key = "#{el.save_to_repository_id}-#{el.build_for_platform_id}"
        next if locked_rep_and_pl.include?(key)
        break if counter > @workers_count
        if create_task(el.save_to_repository_id, el.build_for_platform_id)
          @redis.lpush(LOCKED_REP_AND_PLATFORMS, key)
          counter += 1 
        end
      end
    end

    def self.unlock_build_list(build_list)
      Resque.redis.lrem(LOCKED_BUILD_LISTS, 0, build_list.id)
    end

    def self.unlock_rep_and_platform(build_list)
      key = "#{build_list.save_to_repository_id}-#{build_list.build_for_platform_id}"
      Resque.redis.lrem(LOCKED_REP_AND_PLATFORMS, 0, key)
    end

    private

    def create_task(save_to_repository_id, build_for_platform_id)
      build_lists = BuildList.
        where(:new_core => true, :status => BuildList::BUILD_PUBLISH).
        where(:save_to_repository_id => save_to_repository_id).
        where(:build_for_platform_id => build_for_platform_id).
        where('id NOT IN (?)', @redis.lrange(LOCKED_BUILD_LISTS, 0, -1))

      bl = build_lists.first
      return false unless bl

      platform_path = "#{bl.save_to_platform.path}/repository"
      if bl.save_to_platform.personal?
        platform_path << '/' << bl.build_for_platform.name
        Dir.mkdir(platform_path) unless File.exists?(platform_path)
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
        :time_living => 2400 # 40 min
      }

      packages      = {:sources => [], :binaries => {:x86_64 => [], :i586 => []}}
      old_packages  = packages.clone
      build_list_ids = []

      build_lists.each do |bl|
        fill_packages(bl, packages)
        bl.last_published.includes(:packages).limit(5).each{ |old_bl|
          fill_packages(old_bl, old_packages, :fullname)
        }
        build_list_ids << bl.id
        @redis.lpush(LOCKED_BUILD_LISTS, bl.id)
      end

      Resque.push(
        worker_queue,
        'class' => worker_class,
        'args' => [options.merge({
          :packages => packages,
          :old_packages => old_packages,
          :build_list_ids => build_list_ids
        })]
      )
      return true
    end

    def fill_packages(bl, results_map, field = :sha1)
      # TODO: remove duplicates of sources for different arches
      results_map[:sources] |= bl.packages.by_package_type('source').pluck(field)
      results_map[:binaries][bl.arch.name.to_sym] |= bl.packages.by_package_type('binary').pluck(field)      
    end

  end
end