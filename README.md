# TestWrangler

TestWrangler is an a/b testing platform for Rails, leveraging Rack middleware and a Redis-backed persistence engine for performance.

TestWrangler is designed to integrate with a third party front or back end user tracking service like Mixpanel for metrics and conversion tracking.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'test_wrangler'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install test_wrangler

## Usage

Once TestWrangler is installed, it will inject its middleware and its helper into your application. The middleware is designed to operate independently of any other part of the Rails middleware stack, so that its order in the stack does not matter. TestWrangler will run and attempt to assign test selections to requests as long as the `TEST_WRANGLER` environment variable is set to `'on'`.

TestWrangler exposes a number of configuration options, which should be set in an initializer.

Example initializer with default values explicitly:

```ruby
require 'test_wrangler'

TestWrangler.config do |config|
  config.exclude_paths []
  config.redis Redis.new
  config.root_key :test_wrangler
end
```

### Config Options

- `exclude_paths(*paths)` 
   An array of strings or Regexps to exclude request paths from the middleware. Any string values will be turned into Regexps in the format of `/^(string_pattern)/`. Defaults to empty array
- `redis(redis_instance)`
  A redis instance to use as the base connection for TestWrangler. Defaults to whatever the result of calling `Redis.new` returns
- `root_key(key)`
  The root key to use to namespace TestWrangler data. Defaults to `:test_wrangler`. May be a string or a symbol

### Cohorts and Experiments

Cohorts and experiments are the models that TestWrangler uses to fragment data. 

A cohort represents a segment of traffic. Cohorts can be segmented based on query parameters, cookie values, or user agent strings. The 'priority' of a cohort determines which cohort a request will be assigned to if it matches more than one cohort. Lower priority numbers mean higher priority in matching.

Each cohort can have one or more associated experiments to which it the cohort distributes its traffic. Each experiment may belong to one or more cohorts.

Each experiment in turn can have one or more variants, with each variant being given a weight to determine what proportion of the experiment's assigned traffic will be assigned to each variant. 

Control variants are not automatically set, and variants will be given equal weight if no weights are specified for any variants. If specified weights add to more than 1, the weights are normalized to proportions of 1. If some variants are not specified, and the total specified weight is less than 1, the remainder is divided among the variants with unspecified weights. If the specified weights total to 1 or more, the variants with unspecified weights are given the lowest specified weight, and then all weights are normalized to a proportion of 1.

### Creating a Cohort

TODO: Add dashboard for creating and organizing cohorts.

Example:

```ruby
cohort = TestWrangler::Cohort.new('mobile', 1, {type: :user_agent, user_agent: [/Mobi/]})
TestWrangler.save_cohort(cohort)
```

### Creating an Experiment

TODO: Add dashboard for creating and organizing experiments.

Example:

```ruby
experiment = TestWrangler::Experiment.new('facebook_signup', [:control, :signup_on_cya])
TestWrangler.save_experiment(experiment)
```

### Adding an Experiment to a Cohort

Example:

```ruby
TestWrangler.add_experiment_to_cohort('facebook_signup', 'mobile')
```

### Activating an Experiment/Cohort

Example:

```ruby
TestWrangler.activate_experiment('facebook_signup')
TestWrangler.activate_cohort('facebook')
```

##Helper Methods

TestWrangler provides two helper methods to all controllers and views, `test_wrangler_selection`, and `complete_experiment`. 

`test_wrangler_selection` returns a hash with the test selection in the format `{ cohort: 'cohort_name', experiment: 'experiment_name', variant: 'variant_name'}`. If no selection has been made all keys will be present but the values will be nil.

`complete_experiment` simply erases any TestWrangler cookie that may be set for the user, and returns the test selection as it stood before deleting the cookie. Once the cookie is cleared, the user will be enrolled in a new test on the next request.

##Data Structure

TestWrangler uses RedisNamespace to isolate its data. All keys will begin with `test_wrangler:` unless the `:root_key` config value has been set, in which case that value will be used.

###Experiments

The top level key `experiments` is a set tracking all currently saved experiments. Each experiment also stores its data in the following structure:

- `experiments:experiment_name` (Hash)
  - `variant_name` Weight of the particular variant
  - `variant_name:participant_count` Number of participants in the particular variant
  - `participant_count` Overall participant count for the experiment
  - `state` The experiment state ('active' or nil)
- `experiments:experiment_name:cohorts` Set containing the names of all cohorts associated with the experiment.

###Cohorts

The top level key `cohorts` is a set tracking all currently saved cohorts. Each cohort also stores its priority, serialized matching criteria, experiment associations, and active experiments list in the following keys:

- `cohorts:cohort_name:criteria` Matching criteria serialized as JSON
- `cohorts:cohort_name:priority` Priority of the cohort
- `cohorts:cohort_name:experiments` Set containing all associated experiment names
- `cohorts:cohort_name:active_experiments` List containing the names of all active associated experiments. The list is rotated on each assignment to determine which of the cohort's experiments will be assigned to a particular request.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/test_wrangler.

