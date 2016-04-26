module TestWrangler
  class Cohort
    module Matchers
      class QueryParametersMatcher
        attr_reader :rules
        
        def initialize(*rules)
          @rules = rules.flatten
        end

        def match?(env)
          query_parameters = Rack::Utils.parse_nested_query(env['QUERY_STRING'])
          match = rules.find do |rule|
            rule.all?{|k,v| query_parameters[k] == v}
          end
          !match.nil?
        end

      end
    end
  end
end
