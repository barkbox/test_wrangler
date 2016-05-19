require 'rails_helper'
require 'support/redis'

describe TestWrangler::Config do
  let(:config){TestWrangler::Config.new}
  
  describe '#redis(redis_connection=nil)' do
    context 'with an argument' do
      it 'sets the redis connection' do
        conn = Redis.new
        config.redis(conn)
        expect(config.redis).to eq(conn)
      end
    end
    
    context 'without an argument' do
      it 'returns the default redis connection' do
        expect(config.redis).to be_a(Redis)
      end
    end
  end

  describe '#root_key(key_name=nil)' do
    context 'with an argument' do
      it 'sets the root key' do
        config.root_key(:wrangler_of_tests)
        expect(config.root_key).to eq(:wrangler_of_tests)
      end
    end
    
    context 'without an argument' do
      it 'returns the default root key' do
        expect(config.root_key).to eq(:test_wrangler)
      end
    end
  end

  describe '#exclude_paths(*paths)' do
    context 'with a list of strings and/or regexps' do
      it 'sets the exclusion paths to an array of regexps' do
        output = config.exclude_paths('/api', /^\/butt/)
        expect(output).to eq(config.exclude_paths)
        expect(config.exclude_paths).to eq([/^\/api/, /^\/butt/])
      end
    end

    context 'without an argument' do
      it 'returns an empty array' do
        expect(config.exclude_paths).to eq([])
      end
    end
  end

  describe '#logger(logger=nil)' do
    context 'with an argument' do
      it 'sets the logger' do
        logger = Logger.new(STDOUT)
        config.logger logger
        expect(config.logger).to eq(logger)
      end
    end

    context 'without an argument' do
      it 'returns nil' do
        expect(config.logger).to be_nil
      end
    end  
  end

  describe '#username(username=nil)' do
    before do      
        ENV.delete('TEST_WRANGLER_USER')
    end

    context 'with an argument' do
      it 'sets the username' do
        expect{config.username('admin')}.to change{config.username}.from(nil).to('admin')
      end
    end

    context 'without an argument' do
      context 'if ENV["TEST_WRANGLER_USER"] is set' do
        before do
          ENV["TEST_WRANGLER_USER"] = 'someuser'
        end

        it 'defaults to the env value' do
          expect(config.username).to eq('someuser')
        end
      end
      context 'if no user is set in the ENV' do
        it 'defaults to nil' do
          expect(config.username).to be_nil
        end
      end
    end
  end

  describe '#password(password=nil)' do
    before do      
      ENV.delete('TEST_WRANGLER_PASSWORD')
    end

    context 'with an argument' do
      it 'sets the password' do
        expect{config.password('admin')}.to change{config.password}.from(nil).to('admin')
      end
    end

    context 'without an argument' do
      context 'if ENV["TEST_WRANGLER_USER"] is set' do
        before do
          ENV["TEST_WRANGLER_PASSWORD"] = 'someuser'
        end

        it 'defaults to the env value' do
          expect(config.password).to eq('someuser')
        end
      end

      context 'if no user is set in the ENV' do
        it 'defaults to nil' do
          expect(config.password).to be_nil
        end
      end
    end
  end

end
