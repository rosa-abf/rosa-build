# -*- encoding : utf-8 -*-
module Grack
  class Handler < Base
    def initialize(app, config)
      @app = app
      @config = config
    end

    def call(env)
      super
      if git?
        # TODO event_log?
        project.delay.auto_build if write? # hook
        ::GitHttp::App.new(@config).call(env)
      else
        @app.call(env)
      end
    end
  end
end
