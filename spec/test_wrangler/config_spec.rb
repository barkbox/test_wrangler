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

  describe '#experiments_directory(dirname=nil)' do
    context 'with an argument' do
      it 'sets the path for the experiments directory' do
        config.experiments_directory('/some/directory/somewhere')
        expect(config.experiments_directory).to eq('/some/directory/somewhere')
      end
    end
    
    context 'without an argument' do
      it 'returns nil' do
        expect(config.experiments_directory).to eq(Rails.root.join('config','test_wrangler','experiments'))
      end
    end
  end

  describe '#cohorts_directory(dirname=nil)' do
    context 'with an argument' do
      it 'sets the path for the cohorts directory' do
        config.cohorts_directory('/some/directory/somewhere')
        expect(config.cohorts_directory).to eq('/some/directory/somewhere')
      end
    end
    
    context 'without an argument' do
      it 'returns nil' do
        expect(config.cohorts_directory).to eq(Rails.root.join('config','test_wrangler','cohorts'))
      end
    end
  end

end
