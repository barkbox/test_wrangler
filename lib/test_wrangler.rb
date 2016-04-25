require "test_wrangler/engine"
require 'test_wrangler/errors/errors'
require 'test_rwangler/config'

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

