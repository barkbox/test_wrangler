module TestWrangler
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    before_filter :http_auth

    def http_auth
      creds = ActionController::HttpAuthentication::Basic.decode_credentials(request) rescue nil
      return if creds == "#{TestWrangler.config.username}:#{TestWrangler.config.password}"
      request_http_basic_authentication
    end

  end
end
