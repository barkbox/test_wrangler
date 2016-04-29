require 'test_wrangler/cohort'
require 'active_support/inflector'
require 'test_wrangler/cohort/matchers'

module TestWrangler
  class Cohort
    include Comparable
    attr_reader :name, :criteria, :priority

    def initialize(name, priority, criteria)
      @name = name
      @priority = priority
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


    def <=>(other)
      self.priority <=> other.priority
    end

    def hash
      self.serialize.hash
    end

    def serialize
      serialized_criteria = @original_criteria.map(&:to_json)
      [name, priority, serialized_criteria]
    end

    def self.deserialize(data)
      criteria = data[2].map do |criterion|
        criterion = JSON.parse(criterion)
        type = criterion['type']
        criterion_class = type_to_criterion_class(type)
        criterion[type] = criterion_class.deserialize(criterion[type])
        criterion
      end
      self.new(data[0], data[1].to_i, criteria)
    end

    def self.type_to_criterion_class(type)
        criterion_class_name = ActiveSupport::Inflector.classify("#{type}_matcher")
        ActiveSupport::Inflector.safe_constantize("TestWrangler::Cohort::Matchers::#{criterion_class_name}")
    end

  end
end
