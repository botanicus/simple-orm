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

    attr_reader :presenter
    def initialize(values)
      @presenter = self.class.presenter.new(values)
      @is_new_record = true
    end

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
