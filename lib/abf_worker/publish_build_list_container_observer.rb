module AbfWorker
  class PublishBuildListContainerObserver < AbfWorker::BaseObserver
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

  end
end