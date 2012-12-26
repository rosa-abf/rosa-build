module AbfWorker
  class RpmWorkerObserver < AbfWorker::BaseObserver
    @queue = :rpm_worker_observer

    def self.perform(options)
      bl = BuildList.find options['id']
      status = options['status'].to_i
      item = find_or_create_item(bl)

      fill_container_data(bl, options) if status != STARTED

      case status
      when COMPLETED
        bl.build_success
        item.update_attributes({:status => BuildServer::SUCCESS})
        bl.now_publish if bl.auto_publish?
      when FAILED
        bl.build_error
        item.update_attributes({:status => BuildServer::BUILD_ERROR})
      when STARTED
        bl.start_build
      when CANCELED
        bl.build_canceled
        item.update_attributes({:status => BuildList::BUILD_CANCELED})
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
        if sha1
          bl.container_path = "#{APP_CONFIG['file_store_url']}/api/v1/file_stores/#{sha1}"
          bl.save!
        end
        update_results(bl, options)
      end
    end

  end
end