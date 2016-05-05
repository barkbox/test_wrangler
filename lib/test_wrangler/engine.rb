module TestWrangler
  class Engine < ::Rails::Engine
    isolate_namespace TestWrangler

    initializer "test_wrangler" do |app|
      app.middleware.use TestWrangler::Middleware
      ActionController::Base.send :include, TestWrangler::Helper
      ActionController::Base.helper TestWrangler::Helper
      ActionController::Base.helper_method :test_wrangler_selection, :complete_experiment
    end
    
  end
end
