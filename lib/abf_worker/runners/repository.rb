module AbfWorker
  module Runners
    class Repository < AbfWorker::Runners::Base

      # @param [String] id The id of repository
      def initialize(id, action)
        super action
        @repository = ::Repository.find id
      end

      protected

      def destroy
        platform = @repository.platform
        repository_path = platform.path
        repository_path << '/repository'
        if platform.personal?
          ::Platform.main.pluck(:name).each do |main_platform_name|
            destroy_repositories "#{repository_path}/#{main_platform_name}"
          end
        else
          destroy_repositories repository_path
        end
      end

      def destroy_repositories(repository_path)
        ::Arch.pluck(:name).each do |arch|
          system("rm -rf #{repository_path}/#{arch}/#{@repository.name}")
        end
        system("rm -rf #{repository_path}/SRPMS/#{@repository.name}")
      end

    end
  end
end