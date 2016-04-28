require 'test_wrangler/cohort'
require 'active_support/inflector'
require 'test_wrangler/cohort/matchers'

module TestWrangler
  class Cohort
    attr_reader :name
    attr_reader :criteria

    def initialize(name, criteria)
      @name = name
      @original_criteria = criteria
    end

    def criteria
      @criteria ||= @original_criteria.map do |criterion|
        criterion_class = TestWrangler::Cohort.type_to_criterion_class(criterion[:type])
        criterion_class.new(criterion[criterion[:type]])
      end
    end

    def match?(env)
      criteria.any? do |criterion|
        criterion.match?(env)
      end
    end

    def ==(other)
      other.is_a?(TestWrangler::Cohort) && self.serialize == other.serialize
    end
    alias_method :eql?, :==

    def hash
      self.serialize.hash
    end

    def serialize
      serialized_criteria = @original_criteria.map(&:to_json)
      [name, serialized_criteria]
    end

    def self.deserialize(data)
      criteria = data[1].map do |criterion|
        criterion = JSON.parse(criterion)
        type = criterion['type']
        criterion_class = type_to_criterion_class(type)
        criterion[type] = criterion_class.deserialize(criterion[type])
        criterion
      end
      self.new(data[0], criteria)
    end

    def self.type_to_criterion_class(type)
        criterion_class_name = ActiveSupport::Inflector.classify("#{type}_matcher")
        ActiveSupport::Inflector.safe_constantize("TestWrangler::Cohort::Matchers::#{criterion_class_name}")
    end

  end
end
