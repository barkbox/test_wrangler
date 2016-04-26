module TestWrangler
  class Cohort
    module Matchers
      class CookiesMatcher
        attr_reader :rules
        
        def initialize(*rules)
          @rules = rules.flatten
        end

        def match?(env)
          cookies = Rack::Utils.parse_query(env['HTTP_COOKIE'], ';,') { |s| Rack::Utils.unescape(s) rescue s }
          cookies.each_with_object({}) { |(k,v), hash| hash[k] = Array === v ? v.first : v }
          match = rules.find do |rule|
            rule.all?{|k,v| cookies[k] == v}
          end
          !match.nil?
        end

      end
    end
  end
end
