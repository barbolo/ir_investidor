class Counter
  attr_accessor :key

  def initialize(key)
    self.key  = "counters/#{key}"
  end

  def get
    REDIS.with do |conn|
      conn.get(key).to_i
    end
  end

  def set(value, expiry=1.hour)
    REDIS.with do |conn|
      conn.setex(key, expiry, value)
    end
  end

  def incr(increment=1, expiry=1.hour)
    REDIS.with do |conn|
      conn.pipelined do
        conn.incrby(key, increment)
        conn.expire(key, expiry)
      end
    end.first
  end

  def decr(increment=1, expiry=1.hour)
    REDIS.with do |conn|
      conn.pipelined do
        conn.decrby(key, increment)
        conn.expire(key, expiry)
      end
    end.first
  end

  def expire
    REDIS.with do |conn|
      conn.del(key)
    end
  end
end
