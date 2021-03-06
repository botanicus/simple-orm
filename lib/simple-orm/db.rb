require 'ostruct'

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

    def self.key(key_pattern = nil)
      @key ||= key_pattern
    end

    def self.attributes_in_key
      self.key.scan(/\{(\w+)\}/).flatten
    end

    # Retrieving data using key:
    # Story.get('stories.ppt.1020')
    #
    # Retrieving data using hash values:
    # Story.get(company: 'ppt', id: 1020)

    # The latter method is recommended as
    # it's less prone to changes in the key.
    def self.get(key_or_values)
      key = if key_or_values.respond_to?(:keys)
        key_or_values.reduce(self.key.dup) do |model_key, (key, value)|
          model_key.sub(/\{#{key}\}/, value)
        end
      else
        key_or_values
      end

      raw_values = SimpleORM.redis.hgetall(key)
      return if raw_values.empty?

      values = raw_values.reduce(Hash.new) do |values, (key, raw_value)|
        values.merge(key.to_sym => begin
          # This is because of the dot notation.
          # So for instance if the key is 'users.{company.service.id}',
          # we have to call <user>.company, on that <company>.service
          # and on that <service>.id.
          #
          # OpenStruct is used because attributes are a hash,
          # but latter objects have method_missing for accessing
          # their attributes.
          object = OpenStruct.new(self.presenter.attributes)
          attribute = key.split('.').reduce(object) do |last_object, fragment|
            last_object.send(fragment)
          end
          attribute.deserialise_value(raw_value)
        end)
      end

      self.new(values).tap do |instance|
        instance.is_new_record = false
      end
    end

    def self.get!(*args)
      unless self.get(*args)
        raise "Not found: #{args.inspect}"
      end
    end

    def self.create(values = Hash.new)
      self.new(values).tap(&:save)
    end

    def self.update(values)
      instance = self.get(values)

      if instance.nil?
        self.create(values)
      elsif instance.values != values
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

      "#<#{header} key=#{self.key} values={#{values.join(', ')}}>"
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
