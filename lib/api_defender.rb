require 'rack/throttle'
require 'redis'

# Limit hourly API usage
# http://martinciu.com/2011/08/how-to-add-api-throttle-to-your-rails-app.html
class ApiDefender < Rack::Throttle::Hourly

  def initialize(app)
    options = {
      :cache => Redis.new(:thread_safe => true),
      :key_prefix => :throttle,
      :max => 2000 # only 2000 request per hour
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
    @is_authorized = @user = nil
    [status, heders, body]
  end

  # key increase and key expiration
  def cache_incr(request)
    key = cache_key(request)
    count = cache.incr(key)
    cache.expire(key, 1.day) if count == 1

    if @user
      count = cache.incr(choice_key(request))
      cache.expire(key, 1.day) if count == 1
    end
    count
  end

  protected

  # only API calls should be throttled
  def need_defense?(request)
    APP_CONFIG['allowed_addresses'].exclude?(request.ip) &&
      request.env['PATH_INFO'] =~ /^\/api\/v1\// &&
      !system_user?(request)
  end

  def authorized?(request)
    return @is_authorized if @is_authorized
    auth = Rack::Auth::Basic::Request.new(request.env)
    @user = User.auth_by_token_or_login_pass(*auth.credentials) if auth.provided? and auth.basic?
    @is_authorized = true # cache
  end

  def choice_key request
    return cache_key(request) unless @user
    [@options[:key_prefix], @user.uname, Time.now.strftime('%Y-%m-%dT%H')].join(':')
  end

  def system_user? request
    authorized?(request) && @user.try(:system?)
  end
end
