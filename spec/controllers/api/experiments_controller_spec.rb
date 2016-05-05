require 'rails_helper'
require 'support/auth_helper'
require 'support/redis'

describe TestWrangler::Api::ExperimentsController do
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
    context 'when there are saved experiments' do
      before do
        %w(fixed_header facebook_signup copy_change).each do |name|
          experiment = TestWrangler::Experiment.new(name, [:control, :variant])
          TestWrangler.save_experiment(experiment)
        end
      end

      it "assigns all the experiment names" do
        get :index, format: :json
        expect(assigns["experiments"].length).to eq(3)
      end

      it "assigns the experiment names" do
        get :index, format: :json
        expect(assigns["experiments"]).to eq(['copy_change', 'facebook_signup', 'fixed_header'])
      end
    end

    context 'when there are no saved experiments' do
      it "assigns an empty array" do
        get :index, format: :json
        expect(assigns['experiments']).to be_empty
      end
    end
  end

  describe '#show' do
    let(:experiment) do
      experiment = TestWrangler::Experiment.new('facebook_signup', [:control, :variant])
      TestWrangler.save_experiment(experiment)
      experiment
    end

    context 'when the named experiment exists' do
      before do
        experiment
      end

      it 'assigns the experiment' do
        get :show, {format: :json, experiment_name: 'facebook_signup'}
        expect(assigns['experiment']).to eq(TestWrangler.experiment_json(experiment))
      end

      it 'assigns cohorts' do
        get :show, {format: :json, experiment_name: 'facebook_signup'}
        expect(assigns['cohorts']).to eq([])
        expect(assigns['experiment']['cohorts']).to eq([])
      end

      context 'when the experiment is assigned to cohorts' do
        before do
          cohort = TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: [{'UTM_SOURCE' => 'facebook'}]}])
          TestWrangler.save_cohort(cohort)
          TestWrangler.add_experiment_to_cohort(experiment, cohort)
        end

        it 'assigns the cohorts' do
          get :show, {format: :json, experiment_name: 'facebook_signup'}
          expect(assigns['experiment']['cohorts'].first).to eq('facebook')
          expect(assigns['cohorts'].first).to eq('facebook')
        end
      end
    end

    context 'when the named experiment does not exist' do
      it 'responds with 404' do
        get :show, {format: :json, experiment_name: 'random'}
        expect(response.status).to eq(404)
      end
    end
  end
end
