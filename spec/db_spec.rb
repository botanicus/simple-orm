require 'spec_helper'
require 'simple-orm/db'

describe SimpleORM::DB do
  # Fixtures.
  class UserPresenter < SimpleORM::Presenters::Entity
    attribute(:id).required
    attribute(:username).required
  end

  class User < SimpleORM::DB::Entity
    presenter UserPresenter
  end

  # Spec.
  let(:redis) { Redis.new(driver: :hiredis) }

  before(:each) do
    redis.flushdb
    Time.stub(:now) { Time.at(1403347217) }
  end

  describe SimpleORM::DB::Entity do
    # TODO
  end
end

