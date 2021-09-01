class RpmBuildNode
  MAIN_KEY_FIELDS = [:id, :host]
  REDIS_NAMESPACE = self.name
  LIST_OF_OBJECTS = "#{REDIS_NAMESPACE}:all"

  TTL = 120

  %w(
    id
    host
    user_id
    system
    busy
    query_string
    last_build_id
  ).each { |attr| attr_reader attr }

  def initialize(opts = {})
    opts.keys.each do |key|
      instance_variable_set "@#{key}", opts[key]
    end
  end

  def self.create_or_update(opts = {})
    $redis.with do |r|
      key = MAIN_KEY_FIELDS.map { |key| opts[key] }.join(':')
      redis_name = "#{REDIS_NAMESPACE}:#{key}"
      r.multi do
        r.sadd LIST_OF_OBJECTS, key
        r.setex redis_name, TTL, Oj.dump(opts, mode: :compat)
      end
    end
  end

  def self.all
    Enumerator.new do |y|
      $redis.with do |r|
        r.smembers(LIST_OF_OBJECTS).each do |key|
          json = r.get("#{REDIS_NAMESPACE}:#{key}")
          next if !json
          data = JSON.parse(json)
          y << new(data)
        end
      end
    end
  end

  def self.total_statistics
    systems, others, busy = 0, 0, 0
    all.each do |n|
      if n.system
        systems += n.worker_count
      else
        others += n.worker_count
      end
      busy += n.busy_workers
    end
    { systems: systems, others: others, busy: busy }
  end

  def self.cleanup
    $redis.with do |r|
      r.smembers(LIST_OF_OBJECTS).each do |key|
        item = "#{REDIS_NAMESPACE}:#{key}"
        r.srem LIST_OF_OBJECTS, key if !r.exists(item)
      end
    end
  end
end
