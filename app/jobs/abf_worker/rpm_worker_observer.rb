module AbfWorker
  class RpmWorkerObserver < AbfWorker::BaseObserver
    RESTARTED_BUILD_LISTS = 'abf-worker::rpm-worker-observer::restarted-build-lists'

    # EXIT CODES:
    # 6 - Unpermitted architecture
    # other - Build error
    EXIT_CODE_UNPERMITTED_ARCHITECTURE = 6

    @queue = :rpm_worker_observer

    def self.perform(options)
      new(options, BuildList).perform
    end

    def perform
      return if subject.valid? && restart_task
      if options['feedback_from_user']
        user = User.find options['feedback_from_user']
        return if !user.system? && subject.builder != user
      end

      item = find_or_create_item
      fill_container_data if status != STARTED

      unless subject.valid?
        item.update_attributes({status: BuildList::BUILD_ERROR})
        subject.build_error(false)
        subject.save(validate: false)
        return
      end

      rerunning_tests = subject.rerunning_tests?

      case status
      when COMPLETED
        subject.build_success
        if subject.can_auto_publish? && subject.can_publish?
          subject.now_publish
        elsif subject.auto_publish_into_testing? && subject.can_publish_into_testing?
          subject.publish_into_testing
        end
      when FAILED

        case options['exit_status'].to_i
        when EXIT_CODE_UNPERMITTED_ARCHITECTURE
          subject.unpermitted_arch
        else
          subject.build_error
        end

        item.update_attributes({status: BuildList::BUILD_ERROR}) unless rerunning_tests
      when STARTED
        subject.start_build
      when CANCELED
        item.update_attributes({status: BuildList::BUILD_CANCELED}) unless rerunning_tests || subject.tests_failed?
        subject.build_canceled
      when TESTS_FAILED
        subject.tests_failed
      end

      if !rerunning_tests && [TESTS_FAILED, COMPLETED].include?(status)
        item.update_attributes({status: BuildList::SUCCESS})
        subject.publish_container if subject.auto_create_container?
      end
    end

    protected

    def find_or_create_item
      subject.items.first || subject.items.create({
        version: subject.commit_hash,
        name: subject.project.name,
        status: BuildList::BUILD_STARTED,
        level: 0
      })
    end

    def restart_task
      return false if status != FAILED
      if Redis.current.lrem(RESTARTED_BUILD_LISTS, 0, subject.id) > 0 || (options['results'] || []).size > 1
        return false
      else
        Redis.current.lpush RESTARTED_BUILD_LISTS, subject.id
        subject.update_column(:status, BuildList::BUILD_PENDING)
        subject.restart_job if subject.external_nodes.blank?
        return true
      end
    end

    def fill_container_data
      (options['packages'] || []).each do |package|
        package = subject.packages.build(package)
        package.package_type  = package['fullname'] =~ /.*\.src\.rpm$/ ? 'source' : 'binary'
        package.project_id    = subject.project_id
        package.platform_id   = subject.save_to_platform_id
        package.save!
      end
      update_results
    end

  end
end