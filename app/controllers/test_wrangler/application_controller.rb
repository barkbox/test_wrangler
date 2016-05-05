module TestWrangler
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    before_action :http_auth

    def http_auth
      creds = ActionController::HttpAuthentication::Basic.decode_credentials(request) rescue nil
      return if creds == "#{TestWrangler.config.username}:#{TestWrangler.config.password}"
      render nothing: true, status: :unauthorized
    end

  end
end
