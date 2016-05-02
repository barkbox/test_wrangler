module TestWrangler
  class Engine < ::Rails::Engine
    isolate_namespace TestWrangler

    initializer "test_wrangler.add_middleware" do |app|
      app.middleware.use TestWrangler::Middleware
    end

  end
end
