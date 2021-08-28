class RpmBuildNode
  MAIN_KEY_FIELDS = [:id, :host]
  MODEL_LIST = "#{self.name}:all"

  TTL = 120

  %w(
    id
    user_id
    system
    worker_count
    busy_workers
    host
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
      redis_name = "RpmBuildNode:#{key}"
      data = JSON.parse(r.get(redis_name) || '{}').merge(opts.stringify_keys)
      r.multi do
        r.sadd MODEL_LIST, key
        r.setex redis_name, TTL, Oj.dump(data)
      end
    end
  end

  def self.all
    Enumerator.new do |y|
      $redis.with do |r|
        r.smembers(MODEL_LIST).each do |key|
          data = JSON.parse(r.get("RpmBuildNode:#{key}")) rescue nil
          next if !data
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
      r.smembers(MODEL_LIST).each do |key|
        item = "RpmBuildNode:#{key}"
        r.srem MODEL_LIST, key if !r.exists(item)
      end
    end
  end
end
