require 'spec_helper'
require 'ppt/presenters'

describe PPT::Presenters do
  describe PPT::Presenters::Entity do
    let(:subclass) do
      Class.new(described_class) do |klass|
        attribute(:id).required
        attribute(:username).required
      end
    end

    describe '#validate' do
      it 'throws an error if whatever has been specified as required is missing' do
        expect { subclass.new.validate }.to raise_error(PPT::Presenters::ValidationError)
        expect { subclass.new(Hash.new).validate }.to raise_error(PPT::Presenters::ValidationError)
        expect { subclass.new(username: 'botanicus').validate }.to raise_error(PPT::Presenters::ValidationError)
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

  describe PPT::Presenters::User do
    let(:attrs) {{
      service: 'pt',
      username: 'ppt',
      name: 'PayPerTask Ltd',
      email: 'james@pay-per-task.com',
      accounting_email: 'accounting@pay-per-task.com'
    }}

    it 'raises an exception if service is missing' do
      instance = described_class.new(attrs.reject { |key, value| key == :service })
      expect { instance.validate }.to raise_error(PPT::Presenters::ValidationError)
    end

    it 'raises an exception if username is missing' do
      instance = described_class.new(attrs.reject { |key, value| key == :username })
      expect { instance.validate }.to raise_error(PPT::Presenters::ValidationError)
    end

    it 'raises an exception if name is missing' do
      instance = described_class.new(attrs.reject { |key, value| key == :name })
      expect { instance.validate }.to raise_error(PPT::Presenters::ValidationError)
    end

    it 'raises an exception if email is missing' do
      instance = described_class.new(attrs.reject { |key, value| key == :email })
      expect { instance.validate }.to raise_error(PPT::Presenters::ValidationError)
    end

    it 'returns a valid presenter if all the required arguments have been provided' do
      expect { described_class.new(attrs).validate }.to_not raise_error
    end
  end

  describe PPT::Presenters::Developer do
    let(:attrs) {{
      company: 'ppt',
      username: 'botanicus',
      name: 'James C Russell',
      email: 'contracts@101ideas.cz'
    }}

    it 'raises an exception if company is missing' do
      instance = described_class.new(attrs.reject { |key, value| key == :company })
      expect { instance.validate }.to raise_error(PPT::Presenters::ValidationError)
    end

    it 'raises an exception if username is missing' do
      instance = described_class.new(attrs.reject { |key, value| key == :username })
      expect { instance.validate }.to raise_error(PPT::Presenters::ValidationError)
    end

    it 'raises an exception if name is missing' do
      instance = described_class.new(attrs.reject { |key, value| key == :name })
      expect { instance.validate }.to raise_error(PPT::Presenters::ValidationError)
    end

    it 'raises an exception if email is missing' do
      instance = described_class.new(attrs.reject { |key, value| key == :email })
      expect { instance.validate }.to raise_error(PPT::Presenters::ValidationError)
    end

    it 'returns a valid presenter if all the required arguments have been provided' do
      expect { described_class.new(attrs).validate }.to_not raise_error
    end
  end

  describe PPT::Presenters::Story do
    let(:attrs) {{
      company: 'ppt',
      id: 957456,
      title: 'Implement login',
      price: 120,
      currency: 'GBP',
      link: 'http://www.pivotaltracker.com/story/show/60839620'
    }}

    it 'raises an exception if company is missing' do
      instance = described_class.new(attrs.reject { |key, value| key == :company })
      expect { instance.validate }.to raise_error(PPT::Presenters::ValidationError)
    end

    it 'raises an exception if id is missing' do
      instance = described_class.new(attrs.reject { |key, value| key == :id })
      expect { instance.validate }.to raise_error(PPT::Presenters::ValidationError)
    end

    it 'raises an exception if title is missing' do
      instance = described_class.new(attrs.reject { |key, value| key == :title })
      expect { instance.validate }.to raise_error(PPT::Presenters::ValidationError)
    end

    it 'raises an exception if price is missing' do
      instance = described_class.new(attrs.reject { |key, value| key == :price })
      expect { instance.validate }.to raise_error(PPT::Presenters::ValidationError)
    end

    it 'raises an exception if currency is missing' do
      instance = described_class.new(attrs.reject { |key, value| key == :currency })
      expect { instance.validate }.to raise_error(PPT::Presenters::ValidationError)
    end

    it 'raises an exception if link is missing' do
      instance = described_class.new(attrs.reject { |key, value| key == :link })
      expect { instance.validate }.to raise_error(PPT::Presenters::ValidationError)
    end

    it 'returns a valid presenter if all the required arguments have been provided' do
      expect { described_class.new(attrs).validate }.to_not raise_error
    end
  end
end
