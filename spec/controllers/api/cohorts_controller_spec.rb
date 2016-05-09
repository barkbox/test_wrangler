require 'rails_helper'
require 'support/redis'
require 'support/auth_helper'

describe TestWrangler::Api::CohortsController do
  routes{ TestWrangler::Engine.routes }
  include AuthHelper

  before(:each) do
    TestWrangler.config do |config|
      config.username 'admin'
      config.password 'password'
    end
    http_login('admin','password')
  end

  describe '#index' do
    context 'when there are no saved cohorts' do
      it "assigns an empty array" do
        get :index, format: :json
        expect(assigns['cohorts']).to be_empty
      end
    end
    context 'when there are saved cohorts' do
      before do
        %w(mobile base facebook).each_with_index do |name, priority|
          cohort = TestWrangler::Cohort.new(name, priority, [{type: :universal}])
          TestWrangler.save_cohort(cohort)
        end
      end

      it "assigns all the cohort names in alphabetical order" do
        get :index, format: :json
        expect(assigns['cohorts']).to eq(['base','facebook','mobile'])
      end
    end
  end

end
