module AbfWorker
  class PublishBuildListContainerObserver
    extend AbfWorker::ObserverHelper
    @queue = :publish_build_list_container_observer

    def self.perform(options)
      bl = BuildList.find options['id']
      status = options['status'].to_i
      case status
      when BUILD_COMPLETED
        bl.published
        update_results(bl, options)
      when BUILD_FAILED
        bl.fail_publish
        update_results(bl, options)
      when BUILD_CANCELED
        bl.fail_publish
        update_results(bl, options)
      end
    end

    class << self
      protected

      def update_results(bl, options)
        results = bl.results + options['results']
        bl.results = results.sort_by{ |r| r['file_name'] }
        bl.save!
      end

    end

  end
end