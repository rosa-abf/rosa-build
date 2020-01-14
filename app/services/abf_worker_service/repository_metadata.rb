module AbfWorkerService
  class RepositoryMetadata < Base

    attr_accessor :repository, :repository_status

    def initialize(repository_status)
      @repository_status  = repository_status
      @repository         = repository_status.repository
    end

    def regenerate!
      # Checks mirror sync status
      return if repository.repo_lock_file_exists?

      platform_path = "#{repository.platform.path}/repository"
      if repository.platform.personal?
        platform_path << '/' << build_for_platform.name
        system "mkdir -p #{platform_path}"
      end

      Resque.push(
        'publish_worker_default',
        'class' => 'AbfWorker::PublishWorkerDefault',
        'args' => [{
          id:              Time.now.to_i,
          cmd_params:      cmd_params,
          resign_rpms:     @repository_status.resign_rpms,
          main_script:     'build.sh',
          rollback_script: 'rollback.sh',
          platform:        {
            platform_path:   platform_path,
            type:            build_for_platform.distrib_type,
            name:            build_for_platform.name,
            arch:            'x86_64'
          },
          repository:     {id: repository.id},
          # time_living:     9600, # 160 min
          time_living:    14400, # 240 min
          extra:          {repository_status_id: repository_status.id, regenerate: true}
        }]
      ) if repository_status.start_regeneration

    end

    protected

    def build_for_platform
      @build_for_platform ||= repository_status.platform
    end

    def cmd_params
      {
        'RELEASED'            => repository.platform.released,
        'REPOSITORY_NAME'     => repository.name,
        'TYPE'                => build_for_platform.distrib_type,
        'REGENERATE_METADATA' => true,
        'SAVE_TO_PLATFORM'    => repository.platform.name,
        'BUILD_FOR_PLATFORM'  => build_for_platform.name,
        'FILE_STORE_ADDR'     => APP_CONFIG['file_store_url']
      }.map{ |k, v| "#{k}=#{v}" }.join(' ')
    end

  end
end
