require 'spec_helper'
require 'simple-orm/db'

describe SimpleORM::DB do
  # Fixtures.
  class UserPresenter < SimpleORM::Presenter
    attribute(:id).required
    attribute(:username).required
    attribute(:email).required

    attribute(:accounting_email).default { self.email }
    attribute(:auth_key).private.default { '5c71036005ed1b7abe40ac4a4082db6d' }

    attribute(:created_at).
      deserialise { |data| Time.at(data.to_i) }.
      on_create { Time.now.utc.to_i }

    attribute(:updated_at).
      deserialise { |data| Time.at(data.to_i) }.
      on_update { Time.now.utc.to_i }

    attribute(:extra).
      deserialise { |data| JSON.parse(data) }.
        serialise { |value| value.to_json }
  end

  class User < SimpleORM::DB
    presenter UserPresenter

    def key
      "users.#{self.username}"
    end
  end

  # Spec.
  let(:redis) { Redis.new(driver: :hiredis) }

  before(:each) do
    redis.flushdb
    Time.stub(:now) { Time.at(1403347217) }
  end

  describe 'a model' do
    describe '#save' do
      before(:each) { redis.flushdb }

      it 'saves everything to DB'
    end

    describe '.get' do
      it
    end
  end
end

