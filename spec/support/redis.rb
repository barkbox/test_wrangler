$redis = Redis.new

RSpec.configure do |config|
  config.before(:each) do
    $redis.flushdb
  end
  config.after(:suite) do
    $redis.flushdb
  end
end
