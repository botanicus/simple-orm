require 'spec_helper'
require 'simple-orm/presenters'

describe SimpleORM::Presenters do
  # Fixtures.
  class UserPresenter < SimpleORM::Presenters::Entity
    attribute(:id).required
    attribute(:username).required
  end

  # Spec.
  describe SimpleORM::Presenters::Entity do
    describe '#validate' do
      it 'throws an error if whatever has been specified as required is missing' do
        expect { UserPresenter.new.validate }.to raise_error(SimpleORM::Presenters::ValidationError)
        expect { UserPresenter.new(Hash.new).validate }.to raise_error(SimpleORM::Presenters::ValidationError)
        expect { UserPresenter.new(username: 'botanicus').validate }.to raise_error(SimpleORM::Presenters::ValidationError)
      end

      it 'throws an error if there are any extra arguments' do
        expect { UserPresenter.new(id: 1, username: 'botanicus', extra: 'x') }.to raise_error(ArgumentError)
      end

      it 'succeeds if just the right arguments have been provided' do
        expect { UserPresenter.new(id: 1, username: 'botanicus') }.not_to raise_error
      end
    end

    describe '#values' do
      it 'returns values as a hash' do
        instance = UserPresenter.new(id: 1, username: 'botanicus')
        expect(instance.values[:id]).to eq(1)
        expect(instance.values[:username]).to eq('botanicus')
      end
    end

    describe 'accessors' do
      it 'provides accessors for all the the attributes' do
        instance = UserPresenter.new(id: 1, username: 'botanicus')
        expect(instance.id).to eq(1)
        expect(instance.username).to eq('botanicus')

        expect(instance.respond_to?(:username)).to be(true)
      end
    end

    describe '#to_json' do
      it 'converts #values to JSON' do
        instance = UserPresenter.new(id: 1, username: 'botanicus')
        expect(instance.to_json).to eq('{"id":1,"username":"botanicus"}')
      end
    end
  end
end
