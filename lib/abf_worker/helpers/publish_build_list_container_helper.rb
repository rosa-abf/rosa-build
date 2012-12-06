module AbfWorker
  module Helpers
    module PublishBuildListContainerHelper

      def perform(options)
        initialize_worker BuildList.find(options['id'])
        publish
      end

      private

      def publish
        @build_list.packages.each do |package|
          pdir_srpm = @platsdir + "/" + pname + "/repository/" + bpname + "/SRPMS/" + repo + "/" + version
          pdir_rpm = @platsdir + "/" + pname + "/repository/" + bpname + "/" + arch + "/" + repo + "/" + version
        end
      end

      def initialize_worker(id)
        @build_list = BuildList.find(id)
        save_to_platform = @build_list.save_to_platform
        @plid = save_to_platform.id
        @pname = save_to_platform.name
        @version = save_to_platform.released ? 'updates' : 'release'

        # TODO: where I can find it???
        @platsdir = "#{APP_CONFIG[root]}/platforms"
        @arch = @build_list.arch.name
        # TODO: what is it???
        only_newer = res[0]["only_newer"]

        build_for_platform = @build_list.build_for_platform
        @idbuild_platform = build_for_platform.id
        @bpname = build_for_platform.name

        @blname = "#{@build_list.items.first.name}-#{@build_list.bs_id}"
        @bprid = @build_list.project_id
        @bprname = @build_list.project.name
      end

    end
  end
end