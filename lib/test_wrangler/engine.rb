module TestWrangler
  class Engine < ::Rails::Engine
    isolate_namespace TestWrangler

    initializer "test_wrangler.middlware" do |app|
      app.middleware.use TestWrangler::Middleware
    end

    initializer "test_wrangler.helpers" do |app|
      ActionController::Base.send :include, TestWrangler::Helper
      ActionController::Base.helper TestWrangler::Helper
      ActionController::Base.helper_method :test_wrangler_selection, :complete_experiment
    end

    initializer "test_wrangler.precompile", group: :all do |app|
      app.config.assets.precompile += ["test_wrangler/test_wrangler.js", "test_wrangler/test_wrangler.css"]
    end

    initializer "test_wrangler.static" do |app|
      app.middleware.use(::ActionDispatch::Static, "#{root}/public")
    end
  end
end
