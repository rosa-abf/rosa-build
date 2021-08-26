$redis = ConnectionPool.new(size: 30, timeout: 15) {
  opts = { url: ENV['REDIS_URL'] }
  opts[:logger] = ::Rails.logger if ::Rails.application.config.log_redis
  Redis.new(opts)
}