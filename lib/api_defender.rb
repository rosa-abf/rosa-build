require 'rack/throttle'
require 'redis'

# Limit hourly API usage
# http://martinciu.com/2011/08/how-to-add-api-throttle-to-your-rails-app.html
class ApiDefender < Rack::Throttle::Hourly

  def initialize(app)
    options = {
      :cache => Redis.new(:thread_safe => true),
      :key_prefix => :throttle,
      :max => 500 # only 500 request per hour
    }
    @app, @options = app, options
  end

  # this method checks if request needs throttling.
  # If so, it increases usage counter and compare it with maximum
  # allowed API calls. Returns true if a request can be handled.
  def allowed?(request)
     need_defense?(request) ? cache_incr(request) <= max_per_window : true
  end

  def call(env)
    status, heders, body = super
    request = Rack::Request.new(env)
    # just to be nice for our clients we inform them how many
    # requests remaining does they have
    if need_defense?(request)
      heders['X-RateLimit-Limit']     = max_per_window.to_s
      heders['X-RateLimit-Remaining'] = ([0, max_per_window - (cache_get(choice_key(request)).to_i rescue 1)].max).to_s
    end
    @authorized = nil
    [status, heders, body]
  end

  # key increase and key expiration
  def cache_incr(request)
    key = cache_key(request)
    count = cache.incr(key)
    cache.expire(key, 1.day) if count == 1

    if authorized? request
      count = cache.incr(choice_key(request, :only_user => true))
      cache.expire(key, 1.day) if count == 1
    end
    count
  end

  protected

  # only API calls should be throttled
  def need_defense?(request)
    request.env['PATH_INFO'] =~ /^\/api\/v1\//
  end

  def authorized?(request)
    return @authorized unless @authorized.nil?
    auth = Rack::Auth::Basic::Request.new(request.env)
    if auth.provided? and auth.basic?
      u,pass = auth.credentials
      @authorized = (@user = (User.where(:authentication_token => u).first ||
                     User.find_for_database_authentication(:login => u)) and
                    !@user.access_locked? and
                    (@user.authentication_token == u or @user.valid_password?(pass)))
    end
    @user = nil unless @authorized
    @authorized
  end

  def choice_key request, opts = {}
    raise 'user not authorized for key' if opts[:only_user] && !authorized?(request) # Debug
    return cache_key(request) if opts[:only_ip] || !authorized?(request)
    [@options[:key_prefix], @user.uname, Time.now.strftime('%Y-%m-%dT%H')].join(':')
  end
end
