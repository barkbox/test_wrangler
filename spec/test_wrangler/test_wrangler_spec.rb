require 'rails_helper'
require 'support/redis'

describe TestWrangler do
  describe '::active?' do
    context "when the environment variable TEST_WRANGLER is set to 'on'" do
      before do
        ENV['TEST_WRANGLER'] = 'on'
      end
      it "returns true" do
        expect(TestWrangler).to be_active
      end
    end
    context "when the environment variable TEST_WRANGLER is set to anything else" do
      before do
        ENV['TEST_WRANGLER'] = 'off'
      end
      it "returns false" do
        expect(TestWrangler).to_not be_active
      end
    end
  end

  describe '::save_cohort(cohort)' do
    let(:cohort){TestWrangler::Cohort.new('facebook', [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])}
    context 'when the cohort has a unique name' do
      it 'returns true' do
        expect(TestWrangler.save_cohort(cohort)).to eq(true)
      end
      it 'persists the cohort configuration to redis' do
        expect{TestWrangler.save_cohort(cohort)}.to change{TestWrangler.cohort_exists?(cohort)}.from(false).to(true)
      end
    end
    context 'when the cohort does not have a unique name' do
      it 'returns false' do
        expect(TestWrangler.save_cohort(cohort)).to eq(true)
        expect(TestWrangler.save_cohort(cohort)).to eq(false)
      end
    end
  end

  describe '::remove_cohort(cohort_name)' do
    let(:cohort) do
      cohort = TestWrangler::Cohort.new('facebook', [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])
      TestWrangler.save_cohort(cohort)
      cohort
    end

    context 'when the cohort exists' do
      it 'returns true' do
        expect(TestWrangler.remove_cohort(cohort)).to eq(true)
      end
      it 'removes the cohort from redis' do
        expect{TestWrangler.remove_cohort(cohort)}.to change{TestWrangler.cohort_exists?(cohort)}.from(true).to(false)
      end
    end

    context 'when the cohort does not exist' do
      it 'returns false' do
        expect(TestWrangler.remove_cohort('random')).to eq(false)
      end
    end
  end

  describe '::activate_cohort(cohort)' do
    let(:cohort){TestWrangler::Cohort.new('facebook', [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])}
    it "if the cohort has not been saved it returns false" do
      expect(TestWrangler.activate_cohort(cohort)).to eq(false)
      expect(TestWrangler.cohort_active?(cohort)).to eq(false)
    end
    it "if the cohort exists in redis it returns true" do
      TestWrangler.save_cohort(cohort)
      expect(TestWrangler.activate_cohort(cohort)).to eq(true)
      expect(TestWrangler.cohort_active?(cohort)).to eq(true)
    end
  end

  describe '::deactivate_cohort(cohort)' do
    let(:cohort){TestWrangler::Cohort.new('facebook', [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])}
    it "returns false if the cohort does not exist" do
      expect(TestWrangler.deactivate_cohort(cohort)).to eq(false)
    end
    it "returns true if the cohort name exists in redis" do
      TestWrangler.save_cohort(cohort)
      TestWrangler.activate_cohort(cohort)
      expect(TestWrangler.deactivate_cohort(cohort)).to eq(true)
      expect(TestWrangler.cohort_active?(cohort)).to eq(false)
    end
  end

  describe '::cohort_active?(cohort_name)' do
    before do
      cohort = TestWrangler::Cohort.new('facebook', [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])
      TestWrangler.save_cohort(cohort)
      TestWrangler.activate_cohort(cohort)
    end

    context 'when the cohort exists and its state key is set to "active"' do
      it "returns true" do
        expect(TestWrangler.cohort_active?('facebook')).to eq(true)
      end
    end
    context 'when the cohort does not exist, or its state key is not set to "active"' do
      before do
        TestWrangler.deactivate_cohort('facebook')
      end

      it "returns false" do
        expect(TestWrangler.cohort_active?('facebook')).to eq(false)
        expect(TestWrangler.cohort_active?('random')).to eq(false)
      end
    end
  end

  describe '::save_experiment(experiment)' do
    let(:experiment){TestWrangler::Experiment.new('facebook_signup', [:signup_on_cya])}
    context 'when the experiment has a unique name' do
      it 'returns true' do
        expect(TestWrangler.save_experiment(experiment)).to eq(true)
      end
      it 'persists the experiment configuration to redis' do
        TestWrangler.save_experiment(experiment)
        expect(TestWrangler.experiment_exists?(experiment)).to eq(true)
      end
    end
    context 'when the experiment does not have a unique name' do
      it 'returns false' do
        TestWrangler.save_experiment(experiment)
        expect(TestWrangler.save_experiment(experiment)).to eq(false)
      end
    end
  end

  describe 'active_cohorts' do
    let(:cohort1){TestWrangler::Cohort.new('facebook', [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])}
    let(:cohort2){TestWrangler::Cohort.new('mobile', [{type: :user_agent, user_agent: [/Mobi/]}])}

    context 'when there are active cohorts' do
      before do
        TestWrangler.save_cohort(cohort1)
        TestWrangler.activate_cohort(cohort1)
        TestWrangler.save_cohort(cohort2)
        TestWrangler.activate_cohort(cohort2)
      end

      it 'returns an array of active cohort instances' do
        expect(TestWrangler.active_cohorts).to include(cohort1)
        expect(TestWrangler.active_cohorts).to include(cohort2)
      end
    end

    context 'when there are no active cohorts' do
      it 'returns an empty array' do
        expect(TestWrangler.active_cohorts).to eq([])
      end
    end
  end

  describe '::remove_experiment(experiment)' do
    let(:experiment) do
      experiment = TestWrangler::Experiment.new('facebook_signup', [:signup_on_cya])
      TestWrangler.save_experiment(experiment)
      experiment
    end

    context 'when the experiment exists' do
      it 'returns true' do
        expect(TestWrangler.remove_experiment(experiment)).to eq(true)
      end
      it 'removes the experiment from redis' do
        expect{TestWrangler.remove_experiment(experiment)}.to change{TestWrangler.experiment_exists?(experiment)}.from(true).to(false)
      end
    end

    context 'when the experiment does not exist' do
      it 'returns false' do
        expect(TestWrangler.remove_experiment('random')).to eq(false)
      end
    end
  end

  describe '::activate_experiment(experiment)' do
    let(:experiment){TestWrangler::Experiment.new('facebook_signup', [:signup_on_cya])}
    it "if the experiment has not been saved it returns false" do
      expect(TestWrangler.activate_experiment(experiment)).to eq(false)
      expect(TestWrangler.experiment_active?(experiment)).to eq(false)
    end
    it "if the experiment exists in redis it returns true" do
      TestWrangler.save_experiment(experiment)
      expect(TestWrangler.activate_experiment(experiment)).to eq(true)
      expect(TestWrangler.experiment_active?(experiment)).to eq(true)
    end
  end

  describe '::deactivate_experiment(experiment)' do
    let(:experiment){TestWrangler::Experiment.new('facebook_signup', [:signup_on_cya])}
    it "returns false if the experiment does not exist" do
      expect(TestWrangler.deactivate_experiment(experiment)).to eq(false)
    end
    it "returns true if the experiment name exists in redis" do
      TestWrangler.save_experiment(experiment)
      TestWrangler.activate_experiment(experiment)
      expect(TestWrangler.deactivate_experiment(experiment)).to eq(true)
      expect(TestWrangler.experiment_active?(experiment)).to eq(false)
    end
  end

  describe '::experiment_active?(experiment_name)' do
    before do
      experiment = TestWrangler::Experiment.new('facebook_signup', [:signup_on_cya])
      TestWrangler.save_experiment(experiment)
      TestWrangler.activate_experiment(experiment)
    end

    context 'when the experiment exists and its state key is set to "active"' do
      it "returns true" do
        expect(TestWrangler.experiment_active?('facebook_signup')).to eq(true)
      end
    end
    context 'when the experiment does not exist, or its state key is not set to "active"' do
      before do
        TestWrangler.deactivate_experiment('facebook_signup')
      end

      it "returns false" do
        expect(TestWrangler.experiment_active?('facebook_signup')).to eq(false)
        expect(TestWrangler.experiment_active?('random')).to eq(false)
      end
    end
  end

end
