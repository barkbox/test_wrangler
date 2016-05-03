module TestWrangler
  class Cohort
    module Matchers
    end
  end
end

Dir[File.expand_path('../matchers/*_matcher.rb', __FILE__)].sort.each do |f|
  require f
end

