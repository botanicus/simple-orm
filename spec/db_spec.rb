require 'spec_helper'
require 'simple-orm/db'

describe SimpleORM::DB do
  # Fixtures.
  def userPresenter
    Class.new(SimpleORM::Presenter) do
      attribute(:username).required

      attribute(:email).default do
        "#{self.username}@101ideas.cz"
      end

      attribute(:auth_key).private.default do
        '5c71036005ed1b7abe40ac4a4082db6d'
      end

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
  end

  def userModel(user_presenter)
    Class.new(SimpleORM::DB) do
      presenter user_presenter

      def key
        "users.#{self.presenter.username}"
      end
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

      it 'saves everything to DB' do
        user = userModel(userPresenter).new(username: 'botanicus')
        user.save

        expect(redis.hgetall(user.key)).to eq({
          'username'   => 'botanicus',
          'email'      => 'botanicus@101ideas.cz',
          'auth_key'   => '5c71036005ed1b7abe40ac4a4082db6d',
          'created_at' => '1403347217'
        })
      end

      it 'calls serialisers to serialise whatever is necessary' do
        user = userModel(userPresenter).new(username: 'botanicus', extra: {a: 1, b: 'test'})
        user.save

        expect(redis.hgetall(user.key)).to eq({
          'username'   => 'botanicus',
          'email'      => 'botanicus@101ideas.cz',
          'auth_key'   => '5c71036005ed1b7abe40ac4a4082db6d',
          'extra'      => '{"a":1,"b":"test"}',
          'created_at' => '1403347217'
        })
      end
    end

    describe '.get' do
      it 'returns an object with all the values set up if there is such object' do
        model = userModel(userPresenter)
        user = model.new(username: 'botanicus', extra: {a: 1, b: 'test'})
        user.save

        retrieved_values = model.get(user.key).values
        expect(retrieved_values.keys).to include(:extra)

        # JSON doesn't have symbols, so those are converted to strings.
        expect(retrieved_values[:extra]).to eq('a' => 1, 'b' => 'test')
      end

      it 'returns nil if there is no such object' do
        expect(userModel(userPresenter).get('users:404')).to be(nil)
      end

      it 'properly deserialises all the attributes' do
        model = userModel(userPresenter)
        user = model.new(username: 'botanicus')
        user.save

        retrieved_values = model.get(user.key).values
        expect(retrieved_values.keys.sort).to eq([:auth_key, :created_at, :email, :username])

        expect(retrieved_values[:auth_key]).to eq('5c71036005ed1b7abe40ac4a4082db6d')
        expect(retrieved_values[:created_at]).to eq(Time.at(1403347217))
        expect(retrieved_values[:email]).to eq('botanicus@101ideas.cz')
        expect(retrieved_values[:username]).to eq('botanicus')
      end
    end
  end
end

