module AbfWorker
  class RpmWorkerObserver
    BUILD_COMPLETED = 0
    BUILD_FAILED    = 1
    BUILD_PENDING   = 2
    BUILD_STARTED   = 3
    BUILD_CANCELED  = 4

    @queue = :rpm_worker_observer

    def self.perform(options)
      bl = BuildList.find options['id']
      status = options['status'].to_i
      item = find_or_create_item(bl)
      case status
      when BUILD_COMPLETED
        bl.build_success
        item.update_attributes({:status => BuildServer::SUCCESS})
      when BUILD_FAILED
        bl.build_error
        item.update_attributes({:status => BuildServer::BUILD_ERROR})
      when BUILD_STARTED
        bl.bs_id = bl.id
        bl.save!
        bl.start_build
      when BUILD_CANCELED
        bl.build_canceled
        item.update_attributes({:status => BuildList::BUILD_CANCELED})
      end
      if status != BUILD_STARTED
        fill_container_data bl, options
      end
    end

    class << self
      protected

      def find_or_create_item(bl)
        bl.items.first || bl.items.create({
          :version => bl.commit_hash,
          :name => bl.project.name,
          :status => BuildServer::BUILD_STARTED,
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

        container = (options['results'] || []).
          select{ |r| r['file_name'] !~ /.*\.log$/ }.first
        sha1 = container ? container['sha1'] : nil
        bl.results = options['results']
        bl.container_path = "#{APP_CONFIG['file_store_url']}/#{sha1}" if sha1
        bl.save!
      end
    end

  end
end