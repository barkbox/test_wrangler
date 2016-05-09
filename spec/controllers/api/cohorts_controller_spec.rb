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

  describe '#show' do
    context 'when the cohort does not exist' do
      it 'responds with a 404' do
        get :show, {format: :json, cohort_name: 'random'}
        expect(response.status).to eq(404)
      end
    end
    context 'when the cohort exists' do
      before do
        cohort = TestWrangler::Cohort.new('base', 10, [{type: :universal}])
        TestWrangler.save_cohort(cohort)
        experiment = TestWrangler::Experiment.new(:a_b, [:control, :a, :b])
        TestWrangler.save_experiment(experiment)
        TestWrangler.add_experiment_to_cohort(experiment, cohort)
      end

      it "assigns the cohort json" do
        get :show, {format: :json, cohort_name: 'base'}
        expect(assigns['cohort']['name']).to eq('base')
        expect(assigns['cohort']['priority']).to eq(10)
        expect(assigns['cohort']['criteria']).to eq([{'type' => 'universal'}])
        expect(assigns['cohort']['experiments']).to eq(['a_b'])
        expect(assigns['cohort']['active_experiments']).to eq([])
        expect(response.status).to eq(200)
      end

    end
  end

end
