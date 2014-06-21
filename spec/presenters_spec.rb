require 'spec_helper'
require 'simple-orm/presenters'

describe SimpleORM::Presenters do
  describe SimpleORM::Presenters::Entity do
    let(:subclass) do
      Class.new(described_class) do |klass|
        attribute(:id).required
        attribute(:username).required
      end
    end

    describe '#validate' do
      it 'throws an error if whatever has been specified as required is missing' do
        expect { subclass.new.validate }.to raise_error(SimpleORM::Presenters::ValidationError)
        expect { subclass.new(Hash.new).validate }.to raise_error(SimpleORM::Presenters::ValidationError)
        expect { subclass.new(username: 'botanicus').validate }.to raise_error(SimpleORM::Presenters::ValidationError)
      end

      it 'throws an error if there are any extra arguments' do
        expect { subclass.new(id: 1, username: 'botanicus', extra: 'x') }.to raise_error(ArgumentError)
      end

      it 'succeeds if just the right arguments have been provided' do
        expect { subclass.new(id: 1, username: 'botanicus') }.not_to raise_error
      end
    end

    describe '#values' do
      it 'returns values as a hash' do
        instance = subclass.new(id: 1, username: 'botanicus')
        expect(instance.values[:id]).to eq(1)
        expect(instance.values[:username]).to eq('botanicus')
      end
    end

    describe 'accessors' do
      it 'provides accessors for all the the attributes' do
        instance = subclass.new(id: 1, username: 'botanicus')
        expect(instance.id).to eq(1)
        expect(instance.username).to eq('botanicus')

        expect(instance.respond_to?(:username)).to be(true)
      end
    end

    describe '#to_json' do
      it 'converts #values to JSON' do
        instance = subclass.new(id: 1, username: 'botanicus')
        expect(instance.to_json).to eq('{"id":1,"username":"botanicus"}')
      end
    end
  end
end
