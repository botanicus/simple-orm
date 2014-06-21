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
      values = SimpleORM.redis.hgetall
      self.new(values).tap do |instance|
        instance.is_new_record = false
        instance.attributes.each do |_, attribute|
          attribute.deserialise!
        end
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
      self.values(stage).each do |key, value|
        SimpleORM.redis.hset(self.key, key, value)
      end
    end
  end
end
