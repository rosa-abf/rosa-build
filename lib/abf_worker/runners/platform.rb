module AbfWorker
  module Runners
    class Platform < AbfWorker::Runners::Base

      # @param [String] id The id of platform
      def initialize(id, action)
        super action
        @platform = ::Platform.find id
      end

      protected

      def create
        platform_path = @platform.path
        mk_dir(platform_path)
        ['/projects', '/repository'].each{ |f| mk_dir(platform_path + f) }
      end

      def destroy
        system("rm -rf #{@platform.path}")
      end

    end
  end
end