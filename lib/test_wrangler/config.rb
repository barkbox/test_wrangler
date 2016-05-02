module TestWrangler
  class Config

    def redis(redis_connection=nil)
      @redis ||= redis_connection ? redis_connection : Redis.new
    end

    def root_key(key_name=nil)
      @root_key ||= key_name ? key_name : :test_wrangler
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

  end
end
