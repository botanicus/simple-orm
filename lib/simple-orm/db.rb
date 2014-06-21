require 'redis'
require 'simple-orm/presenters'

class SimpleORM
  def self.redis
    @redis ||= Redis.new(driver: :hiredis)
  end

  class DB
    def self.presenter(klass = nil)
      @presenter ||= klass
    end

    def self.get(key)
      raw_values = SimpleORM.redis.hgetall(key)
      values = raw_values.reduce(Hash.new) do |values, (key, raw_value)|
        values.merge(key.to_sym => begin
          attribute = self.presenter.attributes[key.to_sym]
          attribute.deserialise_value(raw_value)
        end)
      end

      self.new(values).tap do |instance|
        instance.is_new_record = false
      end
    end

    attr_reader :presenter
    def initialize(values)
      @presenter = self.class.presenter.new(values)
      @is_new_record = true
    end

    attr_writer :is_new_record
    def new_record?
      @is_new_record
    end

    def values(stage = nil)
      @presenter.values(stage)
    end

    def save
      stage = self.new_record? ? :create : :update
      self.values(stage).each do |key, _|
        value = self.presenter.attributes[key].serialise_value
        SimpleORM.redis.hset(self.key, key, value)
      end
    end
  end
end
