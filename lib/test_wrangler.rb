require 'test_wrangler/engine'
require 'test_wrangler/errors/errors'
require 'test_wrangler/config'
require 'test_wrangler/experiment'

module TestWrangler
    
    def self.config
      @config ||= TestWrangler::Config.new
      yield @config if block_given?
      @config
    end

    def self.redis
      @redis ||= Redis::Namespace.new(config.root_key, redis: config.redis)
    end

end

