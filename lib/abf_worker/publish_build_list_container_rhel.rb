module AbfWorker
  class PublishBuildListContainerRhel
    extend AbfWorker::Helpers::PublishBuildListContainerHelper
    @queue = :publish_build_list_container_rhel

    # see: PublishBuildListContainerHelper#perform

  end
end