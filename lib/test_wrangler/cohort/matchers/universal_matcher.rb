module TestWrangler
  class Cohort
    module Matchers
      class UniversalMatcher < BaseMatcher

        def initialize(rules=nil)
          @rules = []
        end

        def match?(env)
          true
        end

      end
    end
  end
end
