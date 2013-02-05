module AbfWorker
  class RpmWorkerObserver < AbfWorker::BaseObserver
    TESTS_FAILED  = 5

    @queue = :rpm_worker_observer

    def self.perform(options)
      new(options, BuildList).perform
    end

    protected

    def perform
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

    def find_or_create_item
      subject.items.first || subject.items.create({
        :version => subject.commit_hash,
        :name => subject.project.name,
        :status => BuildList::BUILD_STARTED,
        :level => 0
      })
    end

    def fill_container_data
      packages = options['packages'] || []
      packages.each do |package|
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