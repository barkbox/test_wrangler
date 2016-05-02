module TestWrangler
  class Engine < ::Rails::Engine
    isolate_namespace TestWrangler

    initializer "test_wrangler" do |app|
      app.middleware.use TestWrangler::Middleware
      ActionController::Base.send :include, TestWrangler::Helper
      ActionController::Base.helper TestWrangler::Helper
    end
  end
end
