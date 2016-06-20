module TestWrangler
  class Middleware
    COOKIE_KEYS = [:cohort, :experiment, :variant]
    attr_reader :app

    def initialize(app)
      @app = app
    end

    def log(message, level=:info)
      return unless TestWrangler.logger.present? && (TestWrangler.config.verbose || level == :error)
      TestWrangler.logger.send(level, "[TestWrangler] #{message}")
    end

    def call(env)
      return app.call(env) unless TestWrangler.active? && TestWrangler.valid_request_path?(env['REQUEST_PATH'])

      req = ActionDispatch::Request.new(env)
      selection_from_params = req.query_parameters['TW_SELECTION'].present? ? Hash[COOKIE_KEYS.zip(req.query_parameters['TW_SELECTION'].split(':'))].with_indifferent_access : nil
      log("QP Selection: #{selection_from_params}")
      tw_cookie = JSON.parse(Rack::Utils.unescape(req.cookies['test_wrangler'])).with_indifferent_access rescue nil
      log("QP Cookie: #{tw_cookie}")

      if selection_from_params && selection_from_params != tw_cookie && TestWrangler.experiment_active?(selection_from_params['experiment'])
        log("Selecting from params")
        env['test_wrangler'] = selection_from_params
        status, headers, body = app.call(env)
        resp = ActionDispatch::Response.new(status, headers, body)
        resp.set_cookie('test_wrangler', {value: Rack::Utils.escape(selection_from_params.to_json), domain: TestWrangler.config.cookie_domain})
        resp.to_a
      elsif tw_cookie && TestWrangler.experiment_active?(tw_cookie['experiment'])
        log("Selecting from cookie")
        env['test_wrangler'] = tw_cookie
        app.call(env)
      elsif assignment = TestWrangler.assignment_for(env)
        log("Selecting from assignment")
        env['test_wrangler'] = assignment
        status, headers, body = app.call(env)
        resp = ActionDispatch::Response.new(status, headers, body)
        resp.set_cookie('test_wrangler', {value: Rack::Utils.escape(assignment.to_json), domain: TestWrangler.config.cookie_domain})
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
          log(e.respond_to?(:message) ? e.message : e, :error)
        end
        app.call(env)
    end
  end
end
