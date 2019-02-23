class Redis
  def self.connect!
    opts = { url: ENV['REDIS_URL'] }

    opts[:logger] = ::Rails.logger if ::Rails.application.config.log_redis

    Redis.current = Redis.new(opts)
  end
end

Redis.connect!
