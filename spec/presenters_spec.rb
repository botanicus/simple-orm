require 'spec_helper'
require 'simple-orm/presenters'

describe 'a presenter' do
  # Fixtures.
  def userPresenter
    Class.new(SimpleORM::Presenter) do
      attribute(:id).required
      attribute(:username).required

      namespace(:pt) do
        attribute(:auth_key)
      end
    end
  end

  # Spec.
  describe '#validate' do
    it 'throws an error if whatever has been specified as required is missing' do
      expect { userPresenter.new.validate }.to raise_error(SimpleORM::ValidationError)
      expect { userPresenter.new(Hash.new).validate }.to raise_error(SimpleORM::ValidationError)
      expect { userPresenter.new(username: 'botanicus').validate }.to raise_error(SimpleORM::ValidationError)
    end

    it 'throws an error if there are any extra arguments' do
      expect { userPresenter.new(id: 1, username: 'botanicus', extra: 'x') }.to raise_error(ArgumentError)
    end

    it 'succeeds if just the right arguments have been provided' do
      expect { userPresenter.new(id: 1, username: 'botanicus') }.not_to raise_error
    end
  end

  describe '#values' do
    it 'returns values as a hash' do
      instance = userPresenter.new(id: 1, username: 'botanicus')
      expect(instance.values[:id]).to eq(1)
      expect(instance.values[:username]).to eq('botanicus')
    end
  end

  describe 'accessors' do
    it 'provides getters for all the attributes' do
      instance = userPresenter.new(id: 1, username: 'botanicus')
      expect(instance.id).to eq(1)
      expect(instance.username).to eq('botanicus')

      expect(instance).to respond_to(:username)

      expect(instance.username).to eq('botanicus')
    end

    it 'provides setters for all the public attributes' do
      instance = userPresenter.new(id: 1, username: 'botanicus')

      expect(instance).to respond_to(:username=)

      instance.username = 'john'
      expect(instance.username).to eq('john')
    end

    it 'provides getters for all the namespaces' do
      instance = userPresenter.new(id: 1, username: 'botanicus')

      expect(instance).to respond_to(:pt)
    end
  end

  # TODO: update db_spec.rb as well.
  describe 'namespaces' do
    it 'makes them available in top-level instance #values'

    describe 'accessors' do
      it 'provides getters for all the attributes'
      it 'provides setters for all the public attributes'
    end
  end

  describe '#to_json' do
    it 'deserialises #values to JSON' do
      instance = userPresenter.new(id: 1, username: 'botanicus')
      expect(instance.to_json).to eq('{"id":1,"username":"botanicus"}')
    end
  end
end

describe SimpleORM::Validator do
  let(:validator) do
    described_class.new('is required', &Proc.new {})
  end

  describe '#initialize' do
    it 'takes a message and a block' do
      expect { validator }.not_to raise_error
    end
  end

  describe '#message' do
    it 'is readable' do
      expect(validator.message).to eq('is required')
    end
  end

  describe '#validate!' do
    it 'passes given value to the block provided to #initialize' do
      expect {
        described_class.new('') { |value|
          expect(value).to eq(12)
        }.validate!(:name, 12)
      }.not_to raise_error
    end

    it 'passes if the block provided to #initialize returns true' do
      expect {
        described_class.new('') { true }.validate!(:name, 12)
      }.not_to raise_error
    end

    it 'throws an exception if the block provided to #initialize returns false' do
      expect {
        described_class.new('') { false }.validate!(:name, 12)
      }.to raise_error(SimpleORM::ValidationError)
    end
  end
end
