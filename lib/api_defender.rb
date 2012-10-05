require 'rack/throttle'
require 'redis'

# Limit hourly API usage
# http://martinciu.com/2011/08/how-to-add-api-throttle-to-your-rails-app.html
class ApiDefender < Rack::Throttle::Hourly

  def initialize(app)
    options = {
      :cache => Redis.new(:thread_safe => true),
      :key_prefix => :throttle,
      
      # only 500 request per hour
      :max => 500
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
      heders['X-RateLimit-Remaining'] = ([0, max_per_window - (cache_get(cache_key(request)).to_i rescue 1)].max).to_s
    end
    [status, heders, body]
  end

  # key increase and key expiration
  def cache_incr(request)
    key = cache_key(request)
    count = cache.incr(key)
    cache.expire(key, 1.day) if count == 1
    count
  end

  protected

    # only API calls should be throttled
    def need_defense?(request)
      request.env['PATH_INFO'] =~ /^\/api\/v1\//
    end

end