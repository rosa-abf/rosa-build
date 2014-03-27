# "Coffee's for closers"
class CloseArConnectionsMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  ensure
    ActiveRecord::Base.clear_active_connections! unless env.key?('rack.test')
  end
end
