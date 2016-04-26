Dir[File.expand_path('../matchers/*_matcher.rb', __FILE__)].each do |f|
  require f
end

module TestWrangler
  class Cohort
    module Matchers
    end
  end
end