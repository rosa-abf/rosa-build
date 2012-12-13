module AbfWorker
  module Runners
    class Repository < AbfWorker::Runners::Base

      # @param [String] id The id of repository
      def initialize(id, action)
        super action
        @repository = Repository.find id
      end

      protected

      def create
        platform = @repository.platform
        repository_path = platform.path
        repository_path << '/repository'
        if platform.personal?
          Platform.main.pluck.each do |main_platform_name|
            create_file_tree "#{repository_path}/#{main_platform_name}", true
          end
        else
          create_file_tree repository_path
        end
      end

      def destroy
        platform = @repository.platform
        repository_path = platform.path
        repository_path << '/repository'
        if platform.personal?
          Platform.main.pluck.each do |main_platform_name|
            destroy_repositories "#{repository_path}/#{main_platform_name}"
          end
        else
          destroy_repositories repository_path
        end
      end

      def destroy_repositories(repository_path)
        Arch.pluck(:name).each do |arch|
          system("rm -rf #{repository_path}/#{arch}/#{@repository.name}")
        end
        system("rm -rf #{repository_path}/SRPMS/#{@repository.name}")
      end

      def create_file_tree(repository_path, personal = false)
        # platforms/rosa2012.1/repository
        # platforms/test_personal/repository/rosa2012.1
        mk_dir repository_path
        Arch.pluck(:name).each do |arch|
          path = "#{repository_path}/#{arch}"
          # platforms/rosa2012.1/repository/i586
          # platforms/test_personal/repository/rosa2012.1/i586
          mk_dir path
          path << '/' << @repository.name
          # platforms/rosa2012.1/repository/i586/main
          # platforms/test_personal/repository/rosa2012.1/i586/main
          mk_dir path
          # platforms/rosa2012.1/repository/i586/main/release
          # platforms/test_personal/repository/rosa2012.1/i586/main/release
          mk_dir "#{path}/release"
          # platforms/rosa2012.1/repository/i586/main/updates
          mk_dir "#{path}/updates" unless personal
        end
        path = "#{repository_path}/SRPMS"
        # platforms/rosa2012.1/repository/SRPMS
        # platforms/test_personal/repository/rosa2012.1/SRPMS
        mk_dir path
        path << '/' << @repository.name
        # platforms/rosa2012.1/repository/SRPMS/main
        # platforms/test_personal/repository/rosa2012.1/SRPMS/main
        mk_dir path
        # platforms/rosa2012.1/repository/SRPMS/main/release
        # platforms/test_personal/repository/rosa2012.1/SRPMS/main/release
        mk_dir "#{path}/release"
        # platforms/rosa2012.1/repository/SRPMS/main/updates
        mk_dir "#{path}/updates" unless personal
      end

    end
  end
end