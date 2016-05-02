module TestWrangler
  class Middleware
    attr_reader :app

    def initialize(app)
      @app = app
    end

    def call(env)
      return app.call(env) unless TestWrangler.active? && TestWrangler.valid_request_path?(env['REQUEST_PATH'])

      req = Rack::Request.new(env)
      tw_cookie = JSON.parse(req.cookies['test_wrangler']) rescue nil

      if tw_cookie && TestWrangler.experiment_active?(tw_cookie['experiment'])
        app.call(env)
      elsif assignment = TestWrangler.assignment_for(env)
        status, headers, body = app.call(env)
        resp = Rack::Response.new(body, status, headers)
        resp.set_cookie('test_wrangler', Rack::Utils.escape(assignment.to_json))
        resp.finish
      else
        if tw_cookie
          status, headers, body = app.call(env)
          resp = Rack::Response.new(body, status, headers)
          resp.delete_cookie('test_wrangler')
          resp.finish
        else
          app.call(env)
        end
      end

      rescue Redis::BaseError
        app.call(env)
    end
  end
end
