module TestWrangler
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    http_basic_authenticate_with name: TestWrangler.config.username, password: TestWrangler.config.password
  end
end
