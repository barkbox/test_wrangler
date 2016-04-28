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

  def assignment_for(env)
  end

  def cohort_exists?(cohort_name)
    cohort_name = cohort_name.name if cohort_name.is_a? TestWrangler::Cohort
    redis.sismember('cohorts', cohort_name) rescue false
  end

  def save_cohort(cohort)
    return false if cohort_exists?(cohort.name)
    serialized = cohort.serialize
    key = "cohorts:#{serialized[0]}"
    redis.multi do
      redis.sadd('cohorts', serialized[0])
      redis.rpush("cohorts:#{serialized[0]}:criteria", *serialized[1])
    end
    true
  end

  def remove_cohort(cohort_name)
    cohort_name = cohort_name.name if cohort_name.is_a? TestWrangler::Cohort
    return false unless cohort_exists?(cohort_name)
    rules_key = "cohorts:#{cohort_name}"
    redis.multi do
      redis.srem('cohorts', cohort_name)
      redis.del(rules_key)
    end
    true
  end

  def activate_cohort(cohort_name)
    cohort_name = cohort_name.name if cohort_name.is_a? TestWrangler::Cohort
    return false unless cohort_exists?(cohort_name)
    key = "cohorts:#{cohort_name}:state"
    redis.set(key, 'active')
    true
  end

  def deactivate_cohort(cohort_name)
    cohort_name = cohort_name.name if cohort_name.is_a? TestWrangler::Cohort
    return false unless cohort_exists?(cohort_name)
    key = "cohorts:#{cohort_name}:state"
    redis.set(key, nil)
    true
  end

  def cohort_active?(cohort_name)
    cohort_name = cohort_name.name if cohort_name.is_a? TestWrangler::Cohort
    key = "cohorts:#{cohort_name}:state"
    state = redis.get(key) rescue nil
    state == 'active'
  end
  
  def experiment_exists?(experiment_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    redis.sismember('experiments', experiment_name) rescue false
  end

  def experiment_active?(experiment_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    key = "experiments:#{experiment_name}"
    state = redis.hget(key, 'state') rescue nil
    state == 'active'
  end

  def save_experiment(experiment)
    return false if experiment_exists?(experiment.name)
    serialized = experiment.serialize
    key = "experiments:#{serialized[0]}"
    redis.multi do
      redis.sadd('experiments', serialized[0])
      redis.hmset(key, *serialized[1].to_a)
    end
    true
  end

  def activate_experiment(experiment_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    return false unless experiment_exists?(experiment_name)
    key = "experiments:#{experiment_name}"
    redis.hset(key, 'state', 'active')
    true
  end

  def deactivate_experiment(experiment_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    return false unless experiment_exists?(experiment_name)
    key = "experiments:#{experiment_name}"
    redis.hset(key, 'state', nil)
    true
  end

  def remove_experiment(experiment_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    return false unless experiment_exists?(experiment_name)
    key = "experiments:#{experiment_name}"
    redis.multi do
      redis.srem('experiments', experiment_name)
      redis.del(key)
    end
    true
  end

end

