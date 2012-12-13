module AbfWorker
  module Runners
    class Base

      # @param [String] action The action which should be run (create/destroy)
      def initialize(action)
        @action = action
      end

      def run
        send @action
      end

      def mk_dir(path)
        Dir.mkdir(path) unless File.exists?(path)
      end

    end
  end
end