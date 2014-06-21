require 'json'
require 'ppt/extensions'

class PPT
  module Presenters
    class ValidationError < ::StandardError
    end

    class Validator
      def initialize(message, &block)
        @message, @block = message, block
      end

      def validate!(name, value)
        unless @block.call(value)
          raise ValidationError.new("Value of #{name} is invalid (value is #{value.inspect}).")
        end
      end
    end

    class Attribute
      attr_accessor :instance
      attr_reader :name
      def initialize(name)
        @name = name
        @validators, @hooks = Array.new, Hash.new
      end

      # DSL
      def private
        @private = true
        self
      end

      def required
        @validators << Validator.new('is required') do |value|
          value != nil && ! value.empty?
        end

        self
      end

      def validate(message, &block)
        self.validators << Validator.new(message, &block)
        self
      end

      def type(type)
        @type = type
        self
      end

      def default(value = nil, &block)
        @hooks[:default] = value ? Proc.new { value } : block
        self
      end

      def on_create(value = nil, &block)
        @hooks[:on_create] = value ? Proc.new { value } : block
        self
      end

      def on_update(value = nil, &block)
        @hooks[:on_update] = value ? Proc.new { value } : block
        self
      end

      # API
      def private?
        @private
      end

      def run_hook(name)
        @hooks[name] && @instance.instance_eval(&@hooks[name])
      end

      def set(value)
        if self.private?
          raise "Attribute #{@name} is private!"
        end

        @value = value
      end

      def get(stage = nil)
        if stage.nil?
          @value ||= self.run_hook(:default)
        elsif stage == :create
          @value ||= self.run_hook(:on_create)
        elsif stage == :update
          @value ||= self.run_hook(:on_update)
        else
          raise ArgumentError.new("Attribute#get takes an optional argument which can be either :create or :update.")
        end
      end

      def validate!(stage = nil)
        @validators.each do |validator|
          validator.validate!(self.name, self.get(stage))
        end
      end
    end

    class Entity
      def self.attributes
        @attributes ||= Hash.new
      end

      def self.attribute(name, options = Hash.new)
        self.attributes[name] = Attribute.new(name)
      end

      def initialize(values = Hash.new)
        # Let's consider it safe since this is not user input.
        # It might not be the best idea, but for now, who cares.
        values = PPT.symbolise_keys(values)

        values.each do |key, value|
          unless attribute = self.attributes[key]
            raise ArgumentError.new("No such attribute: #{key}")
          end

          attribute.set(value)
        end
      end

      def attributes
        @attributes ||= self.class.attributes.reduce(Hash.new) do |buffer, (name, attribute)|
          buffer.merge(name => attribute.dup.tap { |attribute| attribute.instance = self })
        end
      end

      def method_missing(name, *args, &block)
        if self.attributes.has_key?(name)
          self.attributes[name].get
        elsif name[-1] == '=' && self.attributes.has_key?(name.to_s[0..-2].to_sym)
          self.attributes[name.to_s[0..-2].to_sym].set(args.first)
        else
          super(name, *args, &block)
        end
      end

      def respond_to_missing?(name, include_private = false)
        self.attributes.has_key?(name) ||
          name[-1] == '=' && self.attributes.has_key?(name.to_s[0..-2].to_sym) ||
          super(name, include_private)
      end

      def values(stage = nil)
        self.attributes.reduce(Hash.new) do |buffer, (name, attribute)|
          value = attribute.get(stage)
          buffer[name] = value if value && value != ''
          buffer
        end
      end

      def to_json
        self.values.to_json
      end

      def validate
        self.attributes.each do |_, attribute|
          attribute.validate!
        end
      end
    end

    # User is either a person or most likely a company.
    #
    # Each user can have only one service, just to make it simple.
    # Besides, not many people use both Jira and Pivotal Tracker.
    require 'securerandom'

    class User < Entity
      attribute(:service).required
      attribute(:username).required
      attribute(:name).required
      attribute(:email).required
      attribute(:accounting_email).default { self.email }
      attribute(:auth_key).private.default { SecureRandom.hex }

      attribute(:created_at).type(Time).on_create { Time.now.utc.to_i }
      attribute(:updated_at).type(Time).on_update { Time.now.utc.to_i }
    end

    class Developer < Entity
      attribute(:company).required
      attribute(:username).required
      attribute(:name).required
      attribute(:email).required

      attribute(:created_at).type(Time).on_create { Time.now.utc.to_i }
      attribute(:updated_at).type(Time).on_update { Time.now.utc.to_i }
    end

    class Story < Entity
      attribute(:company).required
      attribute(:id).required
      attribute(:title).required
      attribute(:price).required
      attribute(:currency).required
      attribute(:link).required

      attribute(:created_at).type(Time).on_create { Time.now.utc.to_i }
      attribute(:updated_at).type(Time).on_update { Time.now.utc.to_i }
    end
  end
end
