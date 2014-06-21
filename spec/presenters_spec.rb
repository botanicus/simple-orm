require 'spec_helper'
require 'simple-orm/presenters'

describe 'a presenter' do
  # Fixtures.
  class UserPresenter < SimpleORM::Presenter
    attribute(:id).required
    attribute(:username).required
  end

  # Spec.
  describe '#validate' do
    it 'throws an error if whatever has been specified as required is missing' do
      expect { UserPresenter.new.validate }.to raise_error(SimpleORM::ValidationError)
      expect { UserPresenter.new(Hash.new).validate }.to raise_error(SimpleORM::ValidationError)
      expect { UserPresenter.new(username: 'botanicus').validate }.to raise_error(SimpleORM::ValidationError)
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
    it 'provides getters for all the attributes' do
      instance = UserPresenter.new(id: 1, username: 'botanicus')
      expect(instance.id).to eq(1)
      expect(instance.username).to eq('botanicus')

      expect(instance.respond_to?(:username)).to be(true)
    end

    it 'provides setters for all the public attributes' do
      instance = UserPresenter.new(id: 1, username: 'botanicus')

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
