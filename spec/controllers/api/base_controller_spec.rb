require 'rails_helper'
require 'support/auth_helper'

describe TestWrangler::Api::BaseController do
  include AuthHelper

  controller do
    def index
      render nothing: true
    end
  end

  context 'request format' do
    before do
      TestWrangler.config do |config|
        config.username 'admin'
        config.password 'password'
      end
      http_login('admin', 'password')
    end
    it 'allows json requests' do
      get :index, format: :json
      expect(response.status).to eq(200)
    end

    it 'dissallows non-json requests' do
      get :index, format: :html
      expect(response.status).to eq(406)
    end
  end
end
