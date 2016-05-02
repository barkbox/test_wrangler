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

end
