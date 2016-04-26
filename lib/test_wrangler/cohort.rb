require 'test_wrangler/cohort'
require 'active_support/inflector'
require 'test_wrangler/cohort/matchers'

module TestWrangler
  class Cohort
    attr_reader :name
    attr_reader :criteria

    def initialize(name, criteria)
      @name = name
      @criteria = criteria.map do |criterion|
        criterion_class_name = ActiveSupport::Inflector.classify(criterion[:type])
        criterion_class = ActiveSupport::Inflector.safe_constantize("TestWrangler::Cohort::Matchers::#{criterion_class_name}Matcher")
        criterion_class.new(criterion[criterion[:type]])
      end
    end

    def match?(env)
      criteria.all? do |criterion|
        criterion.match?(env)
      end
    end

  end
end