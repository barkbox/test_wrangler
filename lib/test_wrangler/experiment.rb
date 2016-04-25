module TestWrangler
  class Experiment
    attr_reader :name, :variants

    def initialize(name, variants=[])
      @name = name
      @variants = Experiment.normalize_variants(name, variants)
    end

    class << self

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
