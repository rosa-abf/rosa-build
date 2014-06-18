module BuildLists
  class CreateContainerJob
    @queue = :middle

    include AbfWorkerHelper

    def self.perform(build_list_id)
      build_list = BuildList.find(build_list_id)

      platform_path = "#{build_list.save_to_platform.path}/container/#{build_list.id}"
      system "rm -rf #{platform_path} && mkdir -p #{platform_path}"

      packages = packages_structure
      packages[:sources] = build_list.packages.by_package_type('source').pluck(:sha1).compact
      packages[:binaries][build_list.arch.name.to_sym] = build_list.packages.by_package_type('binary').pluck(:sha1).compact

      distrib_type  = build_list.build_for_platform.distrib_type
      cmd_params    = {
        'RELEASED'            => false,
        'REPOSITORY_NAME'     => build_list.save_to_repository.name,
        'TYPE'                => distrib_type,
        'IS_CONTAINER'        => true,
        'ID'                  => build_list.id,
        'SAVE_TO_PLATFORM'    => build_list.save_to_platform.name,
        'BUILD_FOR_PLATFORM'  => build_list.build_for_platform.name
      }.map{ |k, v| "#{k}=#{v}" }.join(' ')

      # Low priority
      Resque.push(
        'publish_worker',
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

  end
end