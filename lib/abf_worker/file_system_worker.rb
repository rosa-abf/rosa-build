module AbfWorker
  class FileSystemWorker
    @queue = :file_system_worker

    def self.perform(options)
      id, action = options['id'], options['action']
      case options['type']
      when 'platform'
        @runner = AbfWorker::Runners::Platform.new id, action
      when 'repository'
        @runner = AbfWorker::Runners::Repository.new id, action
      end
      @runner.run
    end

  end
end