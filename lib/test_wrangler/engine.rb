module TestWrangler
  class Engine < ::Rails::Engine
    isolate_namespace TestWrangler

    initializer "test_wrangler.add_middleware" do |app|
      app.middleware.use TestWrangler::Middleware
    end

    intializer "test_wrangler.bootstrap_helper" do |app|
      ActionController::Base.send :include, TestWrangler::Helper
      ActionController::Base.helper TestWrangler::Helper
    end
  end
end
