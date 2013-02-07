module AbfWorker
  class RpmWorkerObserver < AbfWorker::BaseObserver
    RESTARTED_BUILD_LISTS = 'abf-worker::rpm-worker-observer::restarted-build-lists'

    @queue = :rpm_worker_observer

    def self.perform(options)
      new(options, BuildList).perform
    end

    def perform
      return if restart_task

      item = find_or_create_item
      fill_container_data if status != STARTED

      case status
      when COMPLETED
        subject.build_success
        subject.now_publish if subject.auto_publish?
      when FAILED
        subject.build_error
        item.update_attributes({:status => BuildList::BUILD_ERROR})
      when STARTED
        subject.start_build
      when CANCELED
        subject.build_canceled
        item.update_attributes({:status => BuildList::BUILD_CANCELED})
      when TESTS_FAILED
        subject.tests_failed
      end

      item.update_attributes({:status => BuildList::SUCCESS}) if [TESTS_FAILED, COMPLETED].include?(status)
    end

    protected

    def find_or_create_item
      subject.items.first || subject.items.create({
        :version => subject.commit_hash,
        :name => subject.project.name,
        :status => BuildList::BUILD_STARTED,
        :level => 0
      })
    end

    def restart_task
      redis = Resque.redis
      if redis.lrem(RESTARTED_BUILD_LISTS, 0, subject.id) > 0 || status != FAILED || (options['results'] || []).size > 1
        return false
      else
        redis.lpush RESTARTED_BUILD_LISTS, subject.id
        subject.update_column(:status, BuildList::BUILD_PENDING)
        subject.add_job_to_abf_worker_queue
        return true
      end
    end

    def fill_container_data
      (options['packages'] || []).each do |package|
        package = subject.packages.build(package)
        package.package_type = package['fullname'] =~ /.*\.src\.rpm$/ ? 'source' : 'binary'
        package.project_id = subject.project_id
        package.platform_id = subject.save_to_platform_id
        package.save!
      end
      update_results
    end

  end
end