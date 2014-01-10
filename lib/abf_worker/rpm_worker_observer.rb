module AbfWorker
  class RpmWorkerObserver < AbfWorker::BaseObserver
    RESTARTED_BUILD_LISTS = 'abf-worker::rpm-worker-observer::restarted-build-lists'

    @queue = :rpm_worker_observer

    def self.perform(options)
      new(options, BuildList).perform
    end

    def perform
      return if restart_task
      if options['feedback_from_user']
        user = User.find options['feedback_from_user']
        return if !user.system? && subject.builder != user
      end

      item = find_or_create_item
      fill_container_data if status != STARTED

      case status
      when COMPLETED
        subject.build_success
        subject.now_publish if subject.can_auto_publish?
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

      if [TESTS_FAILED, COMPLETED].include?(status)
        item.update_attributes({:status => BuildList::SUCCESS}) 
        subject.publish_container if subject.auto_create_container?
      end
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
      return false if status != FAILED
      redis = Resque.redis
      if redis.lrem(RESTARTED_BUILD_LISTS, 0, subject.id) > 0 || (options['results'] || []).size > 1
        return false
      else
        redis.lpush RESTARTED_BUILD_LISTS, subject.id
        subject.update_column(:status, BuildList::BUILD_PENDING)
        subject.restart_job if subject.external_nodes.blank?
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