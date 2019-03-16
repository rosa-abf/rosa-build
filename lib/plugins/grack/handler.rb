module Grack
  class Handler < Base
    def initialize(app, config)
      @app = app
      @config = config
    end

    def _call(env)
      super
      if git?
        Grack::App.new(@config).call(env)
      else
        @app.call(env)
      end
    end
  end
end
