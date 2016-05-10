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

  describe '#update' do
    context 'when the cohort does not exist' do
      it 'responds with 404' do
        post :update, {format: :json, cohort_name: 'random'}
        expect(response.status).to eq(404)
      end
    end
    context 'when the cohort exists' do
      before do
        cohort = TestWrangler::Cohort.new('base', 10, [{type: :universal}])
        TestWrangler.save_cohort(cohort)
        experiment = TestWrangler::Experiment.new(:a_b, [:control, :a, :b])
        unused_experiment = TestWrangler::Experiment.new(:b_a, [:control])
        TestWrangler.save_experiment(unused_experiment)
        TestWrangler.save_experiment(experiment)
        TestWrangler.add_experiment_to_cohort(experiment, cohort)
        @json = TestWrangler.cohort_json(cohort)
      end

      it 'can update the state, experiments, priority, and criteria' do
        new_json = @json.dup
        new_json[:state] = 'active'
        new_json[:experiments] = ['b_a']
        new_json[:priority] = 0
        new_json[:criteria] = [{type: "query_parameters", query_parameters: [{'hey' => 'now'}]}, {type: "user_agent", user_agent: ['(?-mix:stoowop)']}]
        post :update, {format: :json, cohort_name: 'base', cohort: new_json}
        new_json[:active_experiments] = []
        expect(TestWrangler.cohort_json('base')).to eq(new_json)
      end

    end
  end

end
