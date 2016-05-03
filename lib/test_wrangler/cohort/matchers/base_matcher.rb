module TestWrangler
  class Cohort
    module Matchers
      class BaseMatcher
        attr_reader :rules
        
        def initialize(*rules)
          @rules = [rules].flatten
        end

        def self.deserialize(array)
          array
        end

      end
    end
  end
end
