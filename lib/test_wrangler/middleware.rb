module TestWrangler
  class Middleware
    attr_reader :app

    def initialize(app)
      @app = app
    end

    def call(env)
      return app.call(env) unless TestWrangler.active? && TestWrangler.valid_request_path?(env['REQUEST_PATH'])

      req = ActionDispatch::Request.new(env)
      tw_cookie = JSON.parse(Rack::Utils.unescape(req.cookies['test_wrangler'])).with_indifferent_access rescue nil

      if tw_cookie && TestWrangler.experiment_active?(tw_cookie['experiment'])
        env['test_wrangler'] = tw_cookie
        app.call(env)
      elsif assignment = TestWrangler.assignment_for(env)
        env['test_wrangler'] = assignment
        status, headers, body = app.call(env)
        resp = ActionDispatch::Response.new(status, headers, body)
        resp.set_cookie('test_wrangler', Rack::Utils.escape(assignment.to_json))
        resp.to_a
      else
        if tw_cookie
          status, headers, body = app.call(env)
          resp = ActionDispatch::Response.new(status, headers, body)
          resp.delete_cookie('test_wrangler')
          resp.to_a
        else
          app.call(env)
        end
      end

      rescue Redis::BaseError => e
        unless TestWrangler.logger.nil?
          TestWrangler.logger.error(e)
        end
        app.call(env)
    end
  end
end
