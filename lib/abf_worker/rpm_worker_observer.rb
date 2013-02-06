module AbfWorker
  class RpmWorkerObserver < AbfWorker::BaseObserver
    RESTARTED_BUILD_LISTS = 'abf-worker::rpm-worker-observer::restarted-build-lists'
    @queue = :rpm_worker_observer

    def self.perform(options)
      bl = BuildList.find options['id']
      status = options['status'].to_i

      return if restart_task(bl, status, options)
      
      item = find_or_create_item(bl)
      fill_container_data(bl, options) if status != STARTED

      case status
      when COMPLETED
        bl.build_success
        item.update_attributes({:status => BuildList::SUCCESS})
        bl.now_publish if bl.auto_publish?
      when FAILED
        bl.build_error
        item.update_attributes({:status => BuildList::BUILD_ERROR})
      when STARTED
        bl.start_build
      when CANCELED
        bl.build_canceled
        item.update_attributes({:status => BuildList::BUILD_CANCELED})
      end
    end

    class << self
      protected

      def restart_task(bl, status, options)
        redis = Resque.redis
        if redis.lrem(RESTARTED_BUILD_LISTS, 0, bl.id) > 0 || status != FAILED || (options['results'] || []).size > 1
          return false
        else
          redis.lpush RESTARTED_BUILD_LISTS, bl.id
          bl.update_column(:status, BuildList::BUILD_PENDING)
          bl.add_job_to_abf_worker_queue
          return true
        end
      end

      def find_or_create_item(bl)
        bl.items.first || bl.items.create({
          :version => bl.commit_hash,
          :name => bl.project.name,
          :status => BuildList::BUILD_STARTED,
          :level => 0
        })
      end

      def fill_container_data(bl, options)
        packages = options['packages'] || []
        packages.each do |package|
          package = bl.packages.build(package)
          package.package_type = package['fullname'] =~ /.*\.src\.rpm$/ ? 'source' : 'binary'
          package.project_id = bl.project_id
          package.platform_id = bl.save_to_platform_id
          package.save!
        end
        update_results(bl, options)
      end
    end

  end
end