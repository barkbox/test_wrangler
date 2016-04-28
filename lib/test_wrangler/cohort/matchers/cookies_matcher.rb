module TestWrangler
  class Cohort
    module Matchers
      class CookiesMatcher < BaseMatcher

        def match?(env)
          cookies = Rack::Utils.parse_query(env['HTTP_COOKIE'], ';,') { |s| Rack::Utils.unescape(s) rescue s }.each_with_object({}) { |(k,v), hash| hash[k] = Array === v ? v.first : v }
          match = rules.find do |rule|
            rule.all?{|k,v| cookies[k] == v}
          end
          !match.nil?
        end

      end
    end
  end
end
