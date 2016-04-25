module TestWrangler
  class Config

    def redis(redis_connection=nil)
      @redis ||= redis_connection ? redis_connection : Redis.new
    end

    def root_key(key_name=nil)
      @root_key ||= key_name ? key_name : :test_wrangler
    end

    def experiments_directory(dirname=nil)
      @experiments_directory ||= dirname ? dirname :  rails ? rails.root.join('config', 'test_wrangler', 'experiments') : nil
    end

    def cohorts_directory(dirname=nil)
      @cohorts_directory ||= dirname ? dirname : rails ? rails.root.join('config', 'test_wrangler', 'cohorts') : nil
    end

    def app_root(dir)
      @app_root = dir
    end

    def rails
      @rails = defined?(Rails) ? Rails : nil
    end

  end
end
