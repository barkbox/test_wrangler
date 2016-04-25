module TestWrangler
  class Experiment
    attr_reader :name, :variants

    def initialize(name, variants=[], skip_normalization=false)
      @name = name
      unless skip_normalization
        @variants = Experiment.normalize_variants(name, variants)
      else
        @variants = HashWithIndifferentAccess.new(variants)
      end
    end

    def serialize
      [self.name.to_s, self.variants.stringify_keys]
    end

    def ==(other)
      other.is_a?(TestWrangler::Experiment) && self.name == other.name && self.variants == other.variants
    end
    alias_method :eql?, :==

    def hash
      self.name.hash ^ self.variants.hash
    end

    class << self

      def deserialize(data)
        name, variants = data
        variants.each do |k, v|
          variants[k] = v.to_f
        end
        self.new(name, variants, true)
      end

      def normalize_variants(name, variants)
        if variants.empty?
          h = HashWithIndifferentAccess.new()
          h[name] = 1.0
          h
        elsif variants.any?{|v| v.is_a?(Hash)}
          balance_variant_weights(variants)
        else
          weight = 1.0 / variants.length.to_f
          variants.inject(HashWithIndifferentAccess.new) do |h, v|
            h[v] = weight
            h
          end
        end
      end

      def balance_variant_weights(variants)
        if variants.any?{|v| !v.is_a?(Hash)}
          smallest = nil
          sum = 0.0
          specified = []
          unspecified = []
          variants.each do |v|
            if v.is_a?(Hash)
              weight = v.values.first.to_f
              smallest ||= weight
              smallest = smallest > weight ? weight : smallest
              sum += weight
              specified << v
            else
              unspecified << v
            end
          end

          if sum >= 1.0
            sum += unspecified.length.to_f * smallest
            adjusted_smallest = smallest / sum
            h = HashWithIndifferentAccess.new
            specified.each do |v|
              h[v.keys.first] = v.values.first.to_f / sum
            end
            unspecified.each do |v|
              h[v] = adjusted_smallest
            end
            h
          else
            remainder = 1.0 - sum
            smallest = remainder / unspecified.length.to_f
            variants.inject(HashWithIndifferentAccess.new) do |h, v|
              if v.is_a?(Hash)
                h[v.keys.first] = v.values.first.to_f
              else
                h[v] = smallest
              end
              h
            end
          end
        else
          sum = variants.inject(0.0){|s, v| s + v.values.first.to_f }
          variants.inject(HashWithIndifferentAccess.new()) do |h, v|
            h[v.keys.first] = v.values.first.to_f / sum
            h
          end
        end
      end
    end
  end
end
