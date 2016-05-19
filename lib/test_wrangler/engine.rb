module TestWrangler
  class Engine < ::Rails::Engine
    isolate_namespace TestWrangler

    initializer "test_wrangler.middlware" do |app|
      app.middleware.use TestWrangler::Middleware
      ActionController::Base.helper_method :test_wrangler_selection, :complete_experiment
    end

    initializer "test_wrangler.helpers" do |app|
      ActionController::Base.send :include, TestWrangler::Helper
      ActionController::Base.helper TestWrangler::Helper
    end

    initializer "test_wrangler.precompile", group: :all do |app|
      app.config.assets.paths << root.join("app","assets","templates")
      app.config.assets.precompile += ["test_wrangler/test_wrangler.js", "test_wrangler/test_wrangler.css"]
    end
  end
end
