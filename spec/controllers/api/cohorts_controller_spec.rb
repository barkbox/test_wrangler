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

      it "assigns all the cohorts in alphabetical order" do
        get :index, format: :json
        expect(assigns['cohorts'].map{|c| c[:name]}).to eq(['base','facebook','mobile'])
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
      end

      it 'can update the state, experiments, priority, and criteria' do
        diff = {
          state: 'active',
          experiments: ['b_a'],
          priority: 0,
          criteria: [{type: "query_parameters", query_parameters: [{'hey' => 'now'}]}, {type: "user_agent", user_agent: ['(?-mix:stoowop)']}]
        }
        post :update, {format: :json, cohort_name: 'base', cohort: diff}
        json = TestWrangler.cohort_json('base')
        expect(json[:state]).to eq('active')
        expect(json[:criteria]).to eq([{"type"=> "query_parameters", "query_parameters" => [{'hey'=>'now'}]}.with_indifferent_access, {type: "user_agent", user_agent: ['(?-mix:stoowop)']}.with_indifferent_access])
        expect(json[:experiments]).to eq(['b_a'])
        expect(json[:active_experiments]).to eq([])
      end

    end
  end

  describe '#create' do
    context 'when a cohort by the indicated name already exists' do
      before do
        allow(TestWrangler).to receive(:cohort_exists?).with('random'){true}
      end
      it 'responds with a 409' do
        post :create, {format: :json, cohort: {name: 'random'}}
        expect(response.status).to eq(409)
      end
    end

    context 'when the cohort name is unique' do
      context "when the parameters are valid" do
        it "creates a new cohort" do
          post :create, {format: :json, cohort: {name: 'new_cohort', priority: 0, criteria: [{type: 'universal'}, {type: 'cookies', cookies: [{'facebook' => true}]}, {type: 'user_agent', user_agent: ['(?-mix:what)']}]}}
          expect(TestWrangler.cohort_names).to include('new_cohort')
          expect(TestWrangler.cohort_json('new_cohort').with_indifferent_access[:criteria]).to eq([{type: 'universal'}.with_indifferent_access, {type: 'cookies', cookies: [{'facebook' => true}]}.with_indifferent_access, {type: 'user_agent', user_agent: ['(?-mix:what)']}.with_indifferent_access])
        end
      end
      context "when any parameter is invalid" do
        it "responds with 422" do
          post :create, {format: :json, cohort: {name: 'butt', criteria: 'some variants'}}
          expect(response.status).to eq(422)
        end
      end
    end
  end

  describe '#destroy' do
    context 'when the cohort does not exist' do
      it 'responds with a 404' do
        delete :destroy, {format: :json, cohort_name: 'random'}
        expect(response.status).to eq(404)
      end
    end

    context 'when the cohort does exist' do
      before do
        cohort = TestWrangler::Cohort.new('base', 10, [{type: :universal}])
        TestWrangler.save_cohort(cohort)
      end

      it 'destroys the cohort' do
        delete :destroy, {format: :json, cohort_name: 'base'}
        expect(response.status).to eq(200)
        expect(TestWrangler.cohort_exists?('base')).to eq(false)
      end
    end
  end
end
