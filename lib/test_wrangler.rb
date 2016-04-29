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

  def active_cohorts
    cohort_names = redis.smembers('cohorts') rescue []
    cohort_names.reduce([]) do |arr, cn|
      if cohort_active?(cn)
        criteria = redis.lrange("cohorts:#{cn}:criteria", 0, -1) rescue nil
        arr << TestWrangler::Cohort.deserialize([cn, criteria]) if criteria
      end
      arr
    end
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
    rules_key = "cohorts:#{cohort_name}:criteria"
    experiments_key = "cohorts:#{cohort_name}:experiments"
    active_experiments_key = "cohorts:#{cohort_name}:active_experiments"
    experiments = redis.smembers(experiments_key)
    redis.multi do
      redis.srem('cohorts', cohort_name)
      experiments.each do |experiment|
        redis.srem("experiments:#{experiment}:cohorts", cohort_name)
      end
      redis.del(rules_key, experiments_key, active_experiments_key)
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

  def add_experiment_to_cohort(experiment_name, cohort_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    return false if !experiment_exists?(experiment_name)
    cohort_name = cohort_name.name if cohort_name.is_a? TestWrangler::Cohort
    return false if !cohort_exists?(cohort_name)
    cohort_set_key = "cohorts:#{cohort_name}:experiments"
    experiment_set_key = "experiments:#{experiment_name}:cohorts"
    added = redis.sadd(cohort_set_key, experiment_name)
    redis.sadd(experiment_set_key, cohort_name)

    if added == 1 && experiment_active?(experiment_name)
      list_key = "cohorts:#{cohort_name}:active_experiments"
      redis.rpush(list_key, experiment_name)
    end
    true
  end

  def remove_experiment_from_cohort(experiment_name, cohort_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    return false if !experiment_exists?(experiment_name)
    cohort_name = cohort_name.name if cohort_name.is_a? TestWrangler::Cohort
    return false if !cohort_exists?(cohort_name)
    results = redis.multi do
      redis.srem("cohorts:#{cohort_name}:experiments", experiment_name)
      redis.srem("experiments:#{experiment_name}:cohorts", cohort_name)
    end
    if results[0] && results[1]
      redis.lrem("cohorts:#{cohort_name}:active_experiments", 0, experiment_name) rescue nil
      true
    else
      false
    end
  end

  def cohort_experiments(cohort_name)
    cohort_name = cohort_name.name if cohort_name.is_a? TestWrangler::Cohort
    return false if !cohort_exists?(cohort_name)
    redis.smembers("cohorts:#{cohort_name}:experiments") rescue []
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
    cohorts_key = "#{key}:cohorts"
    cohorts = redis.smembers(cohorts_key)

    redis.multi do
      redis.hset(key, 'state', 'active')
      cohorts.each do |cohort|
        redis.rpush("cohorts:#{cohort}:active_experiments", experiment_name)
      end
    end

    true
  end

  def deactivate_experiment(experiment_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    return false unless experiment_exists?(experiment_name)
    key = "experiments:#{experiment_name}"
    cohorts_key = "#{key}:cohorts"
    cohorts = redis.smembers(cohorts_key)
    
    redis.multi do
      redis.hset(key, 'state', nil)
      cohorts.each do |cohort|
        redis.lrem("cohorts:#{cohort}:active_experiments", 0, experiment_name)
      end
    end
     
    true
  end

  def remove_experiment(experiment_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    return false unless experiment_exists?(experiment_name)
    hash_key = "experiments:#{experiment_name}"
    cohorts_key = "experiments:#{experiment_name}:cohorts"
    cohorts = redis.smembers(cohorts_key)
    
    redis.multi do
      redis.srem('experiments', experiment_name)
      redis.del(hash_key, cohorts_key)
      cohorts.each do |cohort|
        redis.srem("cohorts:#{cohort}:experiments", experiment_name)
        redis.lrem("cohorts:#{cohort}:active_experiments", 0, experiment_name)
      end
    end

    true
  end

end

