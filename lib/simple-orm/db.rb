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

    def self.get(key_or_values)
      if key_or_values.respond_to?(:keys)
        key = self.new(key_or_values).key
      else
        key = key_or_values
      end

      raw_values = SimpleORM.redis.hgetall(key)
      return if raw_values.empty?

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

    def self.create(values = Hash.new)
      self.new(values).tap(&:save)
    end

    def self.update(values)
      instance = self.get(values)

      unless instance.values == values
        instance.save
      end

      instance
    end

    attr_reader :presenter
    def initialize(values = Hash.new)
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
      pairs = self.values(stage).map do |key, _|
        [key, self.presenter.attributes[key].serialise_value]
      end
      SimpleORM.redis.hmset(self.key, *pairs.flatten)
    end
  end
end
