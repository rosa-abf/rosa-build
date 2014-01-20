module Grack
  class Handler < Base
    def initialize(app, config)
      @app = app
      @config = config
    end

    def call(env)
      super
      if git?
        ::GitHttp::App.new(@config).call(env)
      else
        @app.call(env)
      end
    end
  end
end
