$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "test_wrangler/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "test_wrangler"
  s.version     = TestWrangler::VERSION
  s.authors     = ["Erik Sälgström Peterson"]
  s.email       = ["erik@barkbox.com"]
  s.homepage    = "TODO"
  s.summary     = "TestWrangler is an A/B testing plugin for Rails"
  s.description = "TODO: Description of TestWrangler."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.6"
  s.add_dependency "redis", "~> 3.0.4"
  s.add_dependency "redis-namespace", "~> 1.3.2"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "pry"
  s.add_development_dependency "fakeredis"
end
