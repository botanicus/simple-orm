require 'redis'
require 'ppt/presenters'

class PPT
  module DB
    def self.redis
      @redis ||= Redis.new(driver: :hiredis)
    end

    class Entity
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
          PPT::DB.redis.hset(self.key, key, value)
        end
      end
    end

    class User < Entity
      presenter PPT::Presenters::User

      def key
        "users.#{@presenter.username}"
      end
    end

    class Developer < Entity
      presenter PPT::Presenters::Developer

      def key
        "devs.#{@presenter.company}.#{@presenter.username}"
      end
    end

    class Story < Entity
      presenter PPT::Presenters::Story

      def key
        "stories.#{@presenter.company}.#{@presenter.id}"
      end
    end
  end
end
