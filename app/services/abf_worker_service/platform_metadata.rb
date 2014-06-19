module AbfWorkerService
  class PlatformMetadata < Base

    attr_accessor :platform

    def initialize(platform)
      @platform = platform
    end

    def regenerate!
      return unless can_regenerate?(platform)

      Resque.push(
        'publish_worker_default',
        'class' => 'AbfWorker::PublishWorkerDefault',
        'args' => [{
          id:              Time.now.to_i,
          cmd_params:      cmd_params(platform),
          main_script:     'regenerate_platform_metadata.sh',
          platform:        {
            platform_path:   "#{platform.path}/repository",
            type:            platform.distrib_type,
            name:            platform.name,
            arch:            'x86_64'
          },
          time_living:     9600, # 160 min
          extra:           {platform_id: platform.id, regenerate_platform: true}
        }]
      ) if platform.start_regeneration
    end

    protected

    def can_regenerate?
      repos = platform.repositories
      return false if repos.find{ |r| r.repo_lock_file_exists? }

      statuses = RepositoryStatus.where(platform_id: platform.id)
      return true if statuses.blank?

      statuses = statuses.map do |s|
        s.ready? || s.can_start_regeneration? || s.can_start_resign?
      end.uniq
      statuses == [true]
    end

    def cmd_params
      {
        'RELEASED'            => platform.released,
        'REPOSITORY_NAMES'    => platform.repositories.map(&:name).join(','),
        'TYPE'                => platform.distrib_type,
        'REGENERATE_PLATFORM_METADATA' => true,
        'SAVE_TO_PLATFORM'    => platform.name,
        'BUILD_FOR_PLATFORM'  => platform.name
      }.map{ |k, v| "#{k}=#{v}" }.join(' ')
    end

  end
end