require 'test_wrangler/errors/errors'
require 'test_wrangler/config'
require 'test_wrangler/experiment'
require 'test_wrangler/cohort'
require 'test_wrangler/middleware'
require 'test_wrangler/engine'

module TestWrangler
  
  module_function

  def config
    @config ||= TestWrangler::Config.new
    yield @config if block_given?
    @config
  end

  def redis
    @redis ||= Redis::Namespace.new(config.root_key, redis: config.redis)
  end

  def active?
    ENV["TEST_WRANGLER"] == 'on'
  end

  def experiment_active?(experiment_name)
  end

  def assignment_for(env)
  end

end

