module TestWrangler
  class Config

    def redis(redis_connection=nil)
      @redis ||= redis_connection ? redis_connection : Redis.new
    end

    def root_key(key_name=nil)
      @root_key ||= key_name ? key_name : :test_wrangler
    end

    def logger(logger=nil)
      @logger ||= logger
    end

    def exclude_paths(*paths)
      return @exclude_paths if defined? @exclude_paths
      paths = [paths].flatten
      if paths.empty?
        @exclude_paths = paths
      else
        @exclude_paths = paths.map do |path|
          path.is_a?(Regexp) ? path : Regexp.new("^#{Regexp.escape(path)}")
        end
      end
    end

    def username(username=nil)
      if username.nil?
        @username ||= ENV['TEST_WRANGLER_USER']
      else
        @username = username
      end
    end

    def password(password=nil)
      if password.nil?
        @password ||= ENV['TEST_WRANGLER_PASSWORD']
      else
        @password = password
      end
    end

  end
end
