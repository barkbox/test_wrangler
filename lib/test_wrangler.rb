require 'redis'
require 'redis-namespace'
require 'test_wrangler/config'
require 'test_wrangler/experiment'
require 'test_wrangler/cohort'
require 'test_wrangler/middleware'
require 'test_wrangler/helper'
require 'test_wrangler/engine'

module TestWrangler
  NON_VARIANT_KEY_REGEXP=/(:?participant_count)|(^state)$/
  module_function

  def config
    @config ||= TestWrangler::Config.new
    yield @config if block_given?
    @config
  end

  def redis
    @redis ||= Redis::Namespace.new(config.root_key, redis: config.redis)
  end

  def logger
    @logger ||= config.logger
  end

  def active?
    ENV["TEST_WRANGLER"] == 'on'
  end

  def valid_request_path?(path)
    !config.exclude_paths.any?{|p| p =~ path}
  end

  def assignment_for(env)
    cohort = active_cohorts.find do |data|
      instance = TestWrangler::Cohort.deserialize(data)
      instance.match?(env)
    end
    if cohort && (experiment_name = rotate_cohort_experiments(cohort[0])) && (variant_name = next_variant_for(experiment_name))
      increment_experiment_participation(experiment_name, variant_name)
      {cohort: cohort[0], experiment: experiment_name, variant: variant_name}
    else
      nil
    end
  end

  def active_cohorts
    cohort_names = redis.smembers('cohorts') rescue []
    cohorts = cohort_names.reduce([]) do |arr, cn|
      if cohort_active?(cn)
        priority = redis.get("cohorts:#{cn}:priority").to_i
        criteria = redis.lrange("cohorts:#{cn}:criteria", 0, -1) rescue nil
        arr << [cn, priority, criteria]
      end
      arr
    end
    cohorts.empty? ? cohorts : cohorts.sort{|a, b| a[1] <=> b[1]}
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
      redis.set("#{key}:priority", serialized[1])
      redis.rpush("#{key}:criteria", *serialized[2])
    end
    true
  end

  def remove_cohort(cohort_name)
    cohort_name = cohort_name.name if cohort_name.is_a? TestWrangler::Cohort
    return false unless cohort_exists?(cohort_name)
    key = "cohorts:#{cohort_name}"
    criteria_key = "#{key}:criteria"
    priority_key = "#{key}:priority"
    experiments_key = "#{key}:experiments"
    active_experiments_key = "#{key}:active_experiments"
    experiments = redis.smembers(experiments_key)
    redis.multi do
      redis.srem('cohorts', cohort_name)
      experiments.each do |experiment|
        redis.srem("experiments:#{experiment}:cohorts", cohort_name)
      end
      redis.del(criteria_key, experiments_key, active_experiments_key, priority_key)
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

    if added == true && experiment_active?(experiment_name)
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

  def increment_experiment_participation(experiment_name, variant_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    return false if !experiment_exists?(experiment_name)
    variant_exists = redis.hexists("experiments:#{experiment_name}", variant_name) rescue false
    return false if !variant_exists
    redis.multi do
      redis.hincrby("experiments:#{experiment_name}", "participant_count", 1)
      redis.hincrby("experiments:#{experiment_name}", "#{variant_name}:participant_count", 1)
    end
    true
  end

  def experiment_participation(experiment_name, variant_name=nil)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    return false if !experiment_exists?(experiment_name)
    if variant_name
      return false unless redis.hexists("experiments:#{experiment_name}", variant_name) rescue false
      count = redis.hget("experiments:#{experiment_name}", "#{variant_name}:participant_count")
      count ? count.to_i : 0
    else
      count = redis.hget("experiments:#{experiment_name}", "participant_count")
      count ? count.to_i : 0
    end
  end

  def next_variant_for(experiment_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    return false if !experiment_exists?(experiment_name)
    experiment_config = redis.hgetall("experiments:#{experiment_name}")
    experiment_config.delete("state")
    participant_count = experiment_config.delete('participant_count') || 0.0
    participant_count = participant_count.to_f

    weights = experiment_config.reduce({}) do |h, (k,v)|
      next h if k.include?(':participant_count')
      h[k] = v
      experiment_config.delete(k)
      h
    end

    if participant_count == 0.0
      weights.max_by {|k,v| v.to_f }[0]
    else
      diffs = weights.inject({}) do |h, (k,v)|
        count = experiment_config["#{k}:participant_count"]
        count = count.nil? ? 0.0 : count.to_f
        proportion = count / participant_count
        diff = proportion - v.to_f
        h[k] = diff
        h
      end
      diffs.min_by{|k,v| v }[0]
    end
  end

  def active_cohort_experiments(cohort_name)
    cohort_name = cohort_name.name if cohort_name.is_a? TestWrangler::Cohort
    return false if !cohort_exists?(cohort_name)
    redis.lrange("cohorts:#{cohort_name}:active_experiments", 0, -1) rescue []
  end

  def rotate_cohort_experiments(cohort_name)
    cohort_name = cohort_name.name if cohort_name.is_a? TestWrangler::Cohort
    return false if !cohort_exists?(cohort_name)
    key = "cohorts:#{cohort_name}:active_experiments"
    redis.rpoplpush(key, key) rescue nil
  end

  def cohort_experiments(cohort_name)
    cohort_name = cohort_name.name if cohort_name.is_a? TestWrangler::Cohort
    return false if !cohort_exists?(cohort_name)
    redis.smembers("cohorts:#{cohort_name}:experiments") rescue []
  end

  def cohort_names
    redis.smembers('cohorts').sort rescue []
  end

  def experiment_cohorts(experiment_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    return false if !experiment_exists?(experiment_name)
    redis.smembers("experiments:#{experiment_name}:cohorts") rescue []
  end

  def experiment_names
    redis.smembers('experiments').sort rescue []
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

  def experiment_json(experiment_name)
    experiment_name = experiment_name.name if experiment_name.is_a? TestWrangler::Experiment
    return false unless experiment_exists?(experiment_name)
    data, cohorts = redis.multi do
      redis.hgetall("experiments:#{experiment_name}")
      redis.smembers("experiments:#{experiment_name}:cohorts")
    end
    cohorts ||= []
    
    variants = data.reduce([]) do |a, (k,v)|
      unless NON_VARIANT_KEY_REGEXP =~ k.to_s
        h = HashWithIndifferentAccess.new
        h[k] = v.to_f
        a << h
      end
      a
    end

    HashWithIndifferentAccess.new({
      name: experiment_name,
      variants: variants,
      cohorts: cohorts,
      state: data['state'] || 'inactive' 
    })
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
