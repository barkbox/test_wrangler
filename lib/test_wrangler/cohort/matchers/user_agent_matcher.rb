module TestWrangler
  class Cohort
    module Matchers
      class UserAgentMatcher
        attr_reader :rules

        def initialize(*rules)
          @rules = rules.flatten
        end

        def match?(env)
          user_agent = env['HTTP_USER_AGENT'] 
          rules.all? do |rule|
            if rule.is_a? String
              user_agent == rule
            elsif rule.is_a? Regexp
              user_agent =~ rule
            end
          end
        end

      end
    end
  end
end
