require 'rails_helper'
require 'support/auth_helper'

describe TestWrangler::Dashboard::BaseController do
  routes{ TestWrangler::Engine.routes }
  include AuthHelper


  context 'request format' do
    before do
      TestWrangler.config do |config|
        config.username 'admin'
        config.password 'password'
      end
      http_login('admin', 'password')
    end

    it 'allows html requests' do
      get :bootstrap, format: :html
      expect(response.status).to eq(200)
    end

    it 'dissallows non-html requests' do
      get :bootstrap, format: :json
      expect(response.status).to eq(406)
    end
  end
end
