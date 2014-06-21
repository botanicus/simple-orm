require 'spec_helper'
require 'simple-orm/db'

describe SimpleORM::DB do
  let(:redis) { Redis.new(driver: :hiredis) }

  before(:each) do
    redis.flushdb
    Time.stub(:now) { Time.at(1403347217) }
  end

  describe SimpleORM::DB::Entity do
    let(:subclass) do
      Class.new(described_class) do |klass|
        attribute(:id).required
        attribute(:username).required
      end
    end
  end
end

