require 'redis'
require 'simple-orm/presenters'

class SimpleORM
  def self.redis
    @redis ||= Redis.new(driver: :hiredis)
  end

  class DB
    def self.presenter(klass = nil, opts = Hash.new)
      @presenter ||= klass
      @presenter_opts ||= opts
      @presenter
    end

    def self.presenter_opts
      @presenter_opts
    end

    def self.key(key = nil)
      @key ||= key
    end

    def self.attributes_in_key
      self.key.scan(/\{(\w+)\}/).flatten
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

    def omit_list
      ((self.class.attributes_in_key || Array.new) + (self.class.presenter_opts[:omit] || Array.new)).map(&:to_sym)
    end

    def key
      self.class.attributes_in_key.reduce(self.class.key) do |key, attribute_name|
        key.sub("{#{attribute_name}}", self.presenter.send(attribute_name).to_s)
      end
    end

    def save
      stage = self.new_record? ? :create : :update
      pairs = self.values(stage).map do |key, _|
        next if self.omit_list.include?(key)
        [key, self.presenter.attributes[key].serialise_value]
      end.compact
      SimpleORM.redis.hmset(self.key, *pairs.flatten)
    end

    def inspect
      header = "#{self.class}:#{self.object_id}"
      values = self.values.reduce(Array.new) do |array, (key, value)|
        array << "#{key}: #{value.inspect}"
      end

      "#<#{header} key=#{self.key} values={#{values.join(", ")}}>"
    end

    def respond_to_missing?(name, *args)
      @presenter.respond_to?(name, *args) || super(name, *args)
    end

    def method_missing(name, *args, &block)
      if @presenter.respond_to?(name)
        @presenter.send(name, *args, &block)
      else
        super(name, *args, &block)
      end
    end
  end
end
