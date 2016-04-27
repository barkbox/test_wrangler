require 'redis'
require 'redis-namespace'
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

  def experiment_exists?(experiment_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    redis.exists("#{config.root_key}:experiments:#{experiment_name}")
  end

  def experiment_active?(experiment_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    key = "#{config.root_key}:experiments:#{experiment_name}"
    state = redis.hget(key, 'state') rescue nil
    state == 'active'
  end

  def assignment_for(env)
  end
  
  def save_experiment(experiment)
    return false if experiment_exists?(experiment.name)
    serialized = experiment.serialize
    key = "#{config.root_key}:experiments:#{serialized[0]}"
    redis.hmset(key, *serialized[1].to_a)
    true
  end

  def activate_experiment(experiment_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    return false unless experiment_exists?(experiment_name)
    key = "#{config.root_key}:experiments:#{experiment_name}"
    redis.hset(key, 'state', 'active')
    true
  end

  def deactivate_experiment(experiment_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    return false unless experiment_exists?(experiment_name)
    key = "#{config.root_key}:experiments:#{experiment_name}"
    redis.hset(key, 'state', nil)
    true
  end

end

