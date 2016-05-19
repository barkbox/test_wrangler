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

      it "assigns the experiments" do
        get :index, format: :json
        expect(assigns["experiments"].length).to eq(3)
        expect(assigns["experiments"].map{|e| e[:name] }).to eq(['copy_change', 'facebook_signup', 'fixed_header'])
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

  describe '#update' do
    let(:experiment) do
      experiment = TestWrangler::Experiment.new('facebook_signup', [:control, :variant])
      TestWrangler.save_experiment(experiment)
      experiment
    end

    let(:cohort) do
      cohort = TestWrangler::Cohort.new('base', 10, [{type: :universal}])
      TestWrangler.save_cohort(cohort)
      cohort
    end

    context "when the named experiment exists" do
      before do
        cohort
        experiment
      end

      it "can update the experiment's status", :run do
        payload = {state: 'active'} 
        post :update, {format: :json, experiment_name: 'facebook_signup', experiment: payload }
        expect(response.status).to eq(200)
        expect(TestWrangler.experiment_active?('facebook_signup')).to eq(true)
      end

      it "can add the experiment to a cohort" do
        payload = {cohorts: ['base']}
        post :update, { format: :json, experiment_name: 'facebook_signup', experiment: payload }
        expect(response.status).to eq(200)
        expect(TestWrangler.experiment_cohorts('facebook_signup')).to include('base')
      end

      it "can remove the experiment from a cohort" do
        TestWrangler.add_experiment_to_cohort(experiment, cohort)
        payload = {cohorts: []}
        post :update, {format: :json, experiment_name: 'facebook_signup', experiment: payload }
        expect(response.status).to eq(200)
        expect(TestWrangler.experiment_cohorts('facebook_signup')).to be_empty
      end

      it "can't change the variant weights, or add variants" do
        payload = {
          variants: [
            {control: 0.1},
            {variant: 0.9}
          ]
        }
        expect{post :update, {format: :json, experiment_name: 'facebook_signup', experiment: payload}}.to_not change{TestWrangler.experiment_json(experiment)}
      end
    end

    context "when the named experiment does not exist" do
      it "responds with 404" do
        post :update, {format: :json, experiment_name: 'random'}
        expect(response.status).to eq(404)
      end
    end
  end

  describe "#create" do
    context 'when an experiment with the indicated name already exists' do
      before do
        experiment = TestWrangler::Experiment.new('facebook_signup', [:control, :variant])
        TestWrangler.save_experiment(experiment)
      end

      it "responds with 409" do
        post :create, {format: :json, experiment: {name: 'facebook_signup'}}
        expect(response.status).to eq(409)
      end
    end

    context 'when the experiment name is unique' do
      context "when the parameters are valid" do
        it "creates a new experiment" do
          post :create, {format: :json, experiment: {name: 'new_experiment', variants: ['control', 'variant']}}
          expect(TestWrangler.experiment_names).to include('new_experiment')
          expect(TestWrangler.experiment_json('new_experiment').with_indifferent_access[:variants]).to eq([{control: 0.5}.with_indifferent_access, {variant: 0.5}.with_indifferent_access])
        end
      end
      context "when any parameter is invalid" do
        it "responds with 422" do
          post :create, {format: :json, experiment: {name: 'butt', variants: 'some variants'}}
          expect(response.status).to eq(422)
        end
      end
    end
  end

  describe '#destroy' do
    context 'when the experiment exists' do
      before do
        experiment = TestWrangler::Experiment.new('facebook_signup', [:control, :variant])
        TestWrangler.save_experiment(experiment)
      end
      it "destroys the experiment and responds with 200" do
        delete :destroy, {format: :json, experiment_name: 'facebook_signup'}
        expect(response.status).to eq(200)
        expect(TestWrangler.experiment_exists?('facebook_signup')).to eq(false)
      end
    end
    context 'when the experiment does not exist' do
      it "responds with 404" do
        delete :destroy, {format: :json, experiment_name: 'random'}
        expect(response.status).to eq(404)
      end
    end
  end
end
