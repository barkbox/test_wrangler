require 'json'

module TestWrangler
  class Cohort
    module Matchers
      class UserAgentMatcher < BaseMatcher
        REGEX_REGEX = /^(\(\?m?i?x?-?m?i?x?:.*\))+$/
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

        def self.deserialize(rules)
          rules.map do |rule|
            if REGEX_REGEX =~ rule
              Regexp.new(rule)
            else
              rule
            end
          end
        end

      end
    end
  end
end
