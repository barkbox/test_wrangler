require 'rails_helper'
require 'support/auth_helper'

describe TestWrangler::ApplicationController do
  include AuthHelper

  controller do
    def index
      render nothing: true
    end
  end

  describe 'Auth' do
    context 'when credentials are set in the config' do
      before do
        TestWrangler.config do |config|
          config.username 'admin'
          config.password 'password'
        end
      end

      it 'allows requests with the correct credentials' do
        http_login('admin', 'password')
        get :index
        expect(response.status).to eq(200)
      end

      it 'denies requests with incorrect credentials' do    
        get :index
        expect(response.status).to eq(401)
      end
    end

    context 'when no credentials are set' do
      it 'denies all requests' do
        get :index
        expect(response.status).to eq(401)
      end
    end
  end
end
