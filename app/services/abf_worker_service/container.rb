module AbfWorkerService
  class Container < Base

    attr_accessor :build_list

    def initialize(build_list)
      @build_list = build_list
    end

    def create!
      cleanup_folder

      if filter_build_lists_without_packages(build_list).blank?
        build_list.fail_publish_container
        return
      end

      Resque.push(
        'publish_worker', # Low priority
        'class' => 'AbfWorker::PublishWorker',
        'args' => [{
          id:                   build_list.id,
          cmd_params:           cmd_params,
          main_script:          'build.sh',
          rollback_script:      'rollback.sh',
          platform:             {
            platform_path:        platform_path,
            type:                 distrib_type,
            name:                 build_list.build_for_platform.name,
            arch:                 build_list.arch.name
          },
          repository:           {id: build_list.save_to_repository_id},
          time_living:          9600, # 160 min
          packages:             packages,
          old_packages:         packages_structure,
          build_list_ids:       [build_list.id],
          projects_for_cleanup: [],
          extra:                {create_container: true}
        }]
      )
    end

    def destroy!
      system "rm -rf #{platform_path}"
    end

    protected

    def cmd_params
      {
        'RELEASED'            => false,
        'REPOSITORY_NAME'     => build_list.save_to_repository.name,
        'TYPE'                => distrib_type,
        'IS_CONTAINER'        => true,
        'ID'                  => build_list.id,
        'SAVE_TO_PLATFORM'    => build_list.save_to_platform.name,
        'BUILD_FOR_PLATFORM'  => build_list.build_for_platform.name,
        'FILE_STORE_ADDR'     => APP_CONFIG['file_store_url']
      }.map{ |k, v| "#{k}=#{v}" }.join(' ')
    end

    def cleanup_folder
      system "rm -rf #{platform_path} && mkdir -p #{platform_path}"
    end

    def platform_path
      @platform_path ||= "#{build_list.save_to_platform.path}/container/#{build_list.id}"
    end

    def distrib_type
      @distrib_type ||= build_list.build_for_platform.distrib_type
    end

    def packages
      structure = packages_structure
      structure[:sources] = build_list.packages.by_package_type('source').pluck(:sha1).compact
      structure[:binaries][build_list.arch.name.to_sym] = build_list.packages.by_package_type('binary').pluck(:sha1).compact
      structure
    end

  end
end
