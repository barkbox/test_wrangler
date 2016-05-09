require 'rails_helper'
require 'support/redis'

describe TestWrangler do
  describe '.active?' do
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

  describe '.experiment_names' do
    context 'when experiments exist' do
      before do
        %w(fixed_header facebook_signup copy_change).each do |name|
          experiment = TestWrangler::Experiment.new(name, [:control, :variant])
          TestWrangler.save_experiment(experiment)
        end
      end
      
      it "returns all experiment names in alphabetical order" do
        expect(TestWrangler.experiment_names).to eq(['copy_change', 'facebook_signup', 'fixed_header'])
      end
    end

    context 'when no experiments exist' do
      it "returns an empty array" do
        expect(TestWrangler.experiment_names).to eq([])
      end
    end
  end

  describe '.valid_request_path?(path)' do
    before do
      TestWrangler.config do |config|
        config.exclude_paths "/api"
      end
    end

    it 'returns true if the path does not match any paths excluded in the config' do
      expect(TestWrangler.valid_request_path?('/some/great/path')).to eq(true)
      expect(TestWrangler.valid_request_path?('/some/api/path')).to eq(true)
    end

    it 'returns false if the path matches any paths excluded in the config' do
      expect(TestWrangler.valid_request_path?('/api/v2/whatever')).to eq(false)
    end
  end

  describe '.save_cohort(cohort)' do
    let(:cohort){TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])}
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

  describe '.remove_cohort(cohort_name)' do
    let(:cohort) do
      cohort = TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])
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
 
      context 'when the cohort has experiments' do
        before do
          experiment = TestWrangler::Experiment.new('facebook_signup', [:signup_on_cya])
          TestWrangler.save_experiment(experiment)
          TestWrangler.add_experiment_to_cohort(experiment, cohort)
        end

        it 'removes the association' do
          expect{TestWrangler.remove_cohort(cohort)}.to change{TestWrangler.experiment_cohorts('facebook_signup')}
        end
      end
    end

    context 'when the cohort does not exist' do
      it 'returns false' do
        expect(TestWrangler.remove_cohort('random')).to eq(false)
      end
    end
  end

  describe '.activate_cohort(cohort)' do
    let(:cohort){TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])}
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

  describe '.deactivate_cohort(cohort)' do
    let(:cohort){TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])}
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

  describe '.cohort_active?(cohort_name)' do
    before do
      cohort = TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])
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

  describe '.save_experiment(experiment)' do
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

  describe '.cohort_json(cohort_name)' do
    let(:cohort) do
      experiment = TestWrangler::Experiment.new('facebook_signup', [:control, :signup_on_cya])
      cohort = TestWrangler::Cohort.new('base', 10 , [{type: :universal}, {type: :user_agent, user_agent: [/hey/]},{type: :query_parameters, query_parameters: [{'WHAT' => 'YEAH'}]}])
      TestWrangler.save_experiment(experiment)
      TestWrangler.activate_experiment(experiment)
      TestWrangler.save_cohort(cohort)
      TestWrangler.activate_cohort(cohort)
      TestWrangler.add_experiment_to_cohort(experiment, cohort)
      cohort
    end

    it 'returns false if the cohort does not exist' do
      expect(TestWrangler.cohort_json('random')).to eq(false)
    end

    it "serializes the cohort's properties and experiment associations" do
      expected = {
        name: 'base',
        state: 'active',
        priority: 10,
        criteria: [{'type' => 'universal'}, {'type' => 'user_agent', 'user_agent' => ['(?-mix:hey)']}, {'type' => 'query_parameters', 'query_parameters' => [{'WHAT' => 'YEAH'}]}],
        experiments: ['facebook_signup'],
        active_experiments: ['facebook_signup']
      }.with_indifferent_access
      expect(TestWrangler.cohort_json(cohort)).to match(expected)
    end
  end

  describe '.experiment_json(experiment_name)' do
    let(:experiment) do
      experiment = TestWrangler::Experiment.new('facebook_signup', [:control, :signup_on_cya])
      cohort = TestWrangler::Cohort.new('base', 10 , {type: :universal})
      TestWrangler.save_experiment(experiment)
      TestWrangler.activate_experiment(experiment)
      TestWrangler.save_cohort(cohort)
      TestWrangler.add_experiment_to_cohort(experiment, cohort)
      experiment
    end

    it "serializes the experiment's properties and cohort associations" do
      expected = { 
        name: 'facebook_signup', 
        variants: [{control: 0.5}, {signup_on_cya: 0.5}],
        cohorts: ['base'],
        state: 'active'
      }

      expect(TestWrangler.experiment_json(experiment)).to eq(expected.with_indifferent_access)
    end

    it 'returns false if the experiment does not exist' do
      expect(TestWrangler.experiment_json('random')).to eq(false)
    end
  end

  describe '.update_experiment(experiment_name, experiment_json)' do
    context 'when the experiment exists' do

      before do
        experiment = TestWrangler::Experiment.new('facebook_signup', [:control, :signup_on_cya])
        cohort = TestWrangler::Cohort.new('base', 10 , {type: :universal})
        TestWrangler.save_experiment(experiment)
        TestWrangler.save_cohort(cohort)
        TestWrangler.add_experiment_to_cohort(experiment, cohort)
        @json = TestWrangler.experiment_json(experiment)
      end

      it 'can update the experiment cohorts' do
        @json[:cohorts] = []
        expect{TestWrangler.update_experiment('facebook_signup', @json)}.to change{TestWrangler.experiment_json('facebook_signup')[:cohorts]}.to([])
      end

      it 'can update the experiment state' do
        @json[:state] = 'active'
        expect{TestWrangler.update_experiment('facebook_signup', @json)}.to change{TestWrangler.experiment_active?('facebook_signup')}.from(false).to(true)
      end

      it "can't update the experiment variants" do
        @json[:variants] = []
        expect(TestWrangler.update_experiment('facebook_signup', @json)).to eq(false)
      end

    end

    context 'when the experiment does not exist' do
      it 'returns false' do
        expect(TestWrangler.update_experiment('random', {})).to eq(false)
      end
    end
  end

  describe '.cohort_names' do
    let(:cohort1){TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])}
    let(:cohort2){TestWrangler::Cohort.new('mobile', 0, [{type: :user_agent, user_agent: [/Mobi/]}])}

    context 'when there are persisted cohorts' do
      before do
        TestWrangler.save_cohort(cohort1)
        TestWrangler.save_cohort(cohort2)
      end

      it "returns the cohort names in alphabetical order" do
        expect(TestWrangler.cohort_names).to eq(['facebook', 'mobile'])
      end
    end

    context 'when there are no persisted cohorts' do
      it "returns an empty array" do
        expect(TestWrangler.cohort_names).to eq([])
      end
    end
  end

  describe '.active_cohorts' do
    let(:cohort1){TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])}
    let(:cohort2){TestWrangler::Cohort.new('mobile', 0, [{type: :user_agent, user_agent: [/Mobi/]}])}

    context 'when there are active cohorts' do
      before do
        TestWrangler.save_cohort(cohort1)
        TestWrangler.activate_cohort(cohort1)
        TestWrangler.save_cohort(cohort2)
        TestWrangler.activate_cohort(cohort2)
      end

      it 'returns a sorted array of active cohort data' do
        expect(TestWrangler.active_cohorts).to include(cohort1.serialize)
        expect(TestWrangler.active_cohorts).to include(cohort2.serialize)
      end
    end

    context 'when there are no active cohorts' do
      it 'returns an empty array' do
        expect(TestWrangler.active_cohorts).to eq([])
      end
    end
  end

  describe '.add_experiment_to_cohort(experiment_name, cohort_name)' do
    let(:experiment) do
      experiment = TestWrangler::Experiment.new('facebook_signup', [:signup_on_cya])
      TestWrangler.save_experiment(experiment)
      experiment
    end
    
    let(:cohort) do
      cohort = TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])
      TestWrangler.save_cohort(cohort)
      cohort
    end

    context 'when both the experiment and the cohort exist in redis' do
      it 'returns true' do
        expect(TestWrangler.add_experiment_to_cohort(experiment, cohort)).to eq(true)
      end
      it 'attaches the experiment to the cohort' do
        expect{TestWrangler.add_experiment_to_cohort(experiment, cohort)}.to change{TestWrangler.cohort_experiments(cohort)}
      end

      context 'when the experiment is active' do
        before do
          TestWrangler.activate_experiment(experiment)
        end

        it "adds the experiment to the cohort's active experiments" do
          expect{TestWrangler.add_experiment_to_cohort(experiment, cohort)}.to change{TestWrangler.active_cohort_experiments(cohort)}
        end
      end
    end

    context 'when either the experiment or the cohort do not exist in redis' do
      it 'returns false' do
        expect(TestWrangler.add_experiment_to_cohort('some_random_experiment', cohort)).to eq(false)
        expect(TestWrangler.add_experiment_to_cohort(experiment, 'some_random_cohort')).to eq(false)
      end
      it 'does not change redis data' do
        expect{TestWrangler.add_experiment_to_cohort('some_random_experiment', cohort)}.to_not change{TestWrangler.cohort_experiments(cohort)}
      end
    end
  end

  describe '.remove_experiment_from_cohort(experiment_name, cohort_name)' do
    let(:experiment) do
      experiment = TestWrangler::Experiment.new('facebook_signup', [:signup_on_cya])
      TestWrangler.save_experiment(experiment)
      experiment
    end
    
    let(:cohort) do
      cohort = TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])
      TestWrangler.save_cohort(cohort)
      cohort
    end

    context 'when the experiment is a member of the cohort' do
      before do
        TestWrangler.add_experiment_to_cohort(experiment, cohort)
      end

      it 'returns true' do
        expect(TestWrangler.remove_experiment_from_cohort(experiment, cohort)).to eq(true)
      end

      it 'removes the experiment from the cohort' do
        expect{TestWrangler.remove_experiment_from_cohort(experiment, cohort)}.to change{TestWrangler.cohort_experiments(cohort)}
      end
    end

    context 'when the experiment is not a member of the cohort' do
      it 'returns false' do
        expect(TestWrangler.remove_experiment_from_cohort(experiment, cohort)).to eq(false)
      end
    end

    context 'when the experiment or cohort do not exist' do
      it 'returns false' do
        expect(TestWrangler.remove_experiment_from_cohort('shoop', cohort)).to eq(false)
        expect(TestWrangler.remove_experiment_from_cohort(experiment, 'shoop')).to eq(false)
      end
    end
  end

  describe '.cohort_experiments(cohort_name)' do
    let(:experiment) do
      experiment = TestWrangler::Experiment.new('facebook_signup', [:signup_on_cya])
      TestWrangler.save_experiment(experiment)
      experiment
    end
    
    let(:cohort) do
      cohort = TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])
      TestWrangler.save_cohort(cohort)
      cohort
    end

    context 'when experiments have been added to the cohort' do
      before do
        TestWrangler.add_experiment_to_cohort(experiment, cohort)
      end
      it 'returns a list of experiment names' do
        expect(TestWrangler.cohort_experiments(cohort)).to eq(['facebook_signup'])
      end
    end

    context 'when no experiments have been added to the cohort' do
      it 'returns an empty list' do
        expect(TestWrangler.cohort_experiments(cohort)).to be_empty
      end
    end

    context 'when the cohort does not exist' do
      it 'returns false' do
        expect(TestWrangler.cohort_experiments('random')).to eq(false)
      end
    end
  end

  describe '.active_cohort_experiments(cohort_name)' do
    let(:experiment) do
      experiment = TestWrangler::Experiment.new('facebook_signup', [:signup_on_cya])
      TestWrangler.save_experiment(experiment)
      TestWrangler.activate_experiment(experiment)
      experiment
    end
    
    let(:cohort) do
      cohort = TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])
      TestWrangler.save_cohort(cohort)
      cohort
    end

    context 'when active experiments have been added to the cohort' do
      before do
        TestWrangler.add_experiment_to_cohort(experiment, cohort)
      end
      it 'returns a list of experiment names' do
        expect(TestWrangler.active_cohort_experiments(cohort)).to eq(['facebook_signup'])
      end
    end

    context 'when no active experiments have been added to the cohort' do
      it 'returns an empty list' do
        expect(TestWrangler.active_cohort_experiments(cohort)).to be_empty
      end
    end

    context 'when the cohort does not exist' do
      it 'returns false' do
        expect(TestWrangler.active_cohort_experiments('random')).to eq(false)
      end
    end
  end

  describe '.rotate_cohort_experiments(cohort_name)' do
    let(:experiment1) do
      experiment = TestWrangler::Experiment.new('facebook_signup', [:signup_on_cya])
      TestWrangler.save_experiment(experiment)
      TestWrangler.activate_experiment(experiment)
      experiment
    end

    let(:experiment2) do
      experiment = TestWrangler::Experiment.new('the_copy', [:new_copy])
      TestWrangler.save_experiment(experiment)
      TestWrangler.activate_experiment(experiment)
      experiment
    end

    let(:cohort) do
      cohort = TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])
      TestWrangler.save_cohort(cohort)
      cohort
    end

    context 'when the cohort does not exist' do
      it 'returns false' do
        expect(TestWrangler.rotate_cohort_experiments('random')).to eq(false)
      end
    end

    context 'when the cohort has a single active experiment' do
      before do
        TestWrangler.add_experiment_to_cohort(experiment1, cohort)
      end
      it 'always returns that experiment name' do
        2.times{ expect(TestWrangler.rotate_cohort_experiments(cohort)).to eq('facebook_signup')}
      end
    end

    context 'when the cohort has more than one active experiment' do
      before do
        TestWrangler.add_experiment_to_cohort(experiment1, cohort)
        TestWrangler.add_experiment_to_cohort(experiment2, cohort)
      end

      it 'rotates the experiments and returns the experiment that was at the tail of the list' do
        expect(TestWrangler.rotate_cohort_experiments(cohort)).to eq('the_copy')
        expect(TestWrangler.rotate_cohort_experiments(cohort)).to eq('facebook_signup')
        expect(TestWrangler.rotate_cohort_experiments(cohort)).to eq('the_copy')
      end
    end

    context 'when the cohort has no active experiments' do
      it 'returns nil' do
        expect(TestWrangler.rotate_cohort_experiments(cohort)).to be_nil
      end
    end
  end

  describe '.experiment_cohorts(experiment_name)' do
    let(:experiment) do
      experiment = TestWrangler::Experiment.new('facebook_signup', [:signup_on_cya])
      TestWrangler.save_experiment(experiment)
      experiment
    end
    
    let(:cohort) do
      cohort = TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])
      TestWrangler.save_cohort(cohort)
      cohort
    end

    context 'when the experiment has been added to cohorts' do
      before do
        TestWrangler.add_experiment_to_cohort(experiment, cohort)
      end
      it 'returns a list of cohort names' do
        expect(TestWrangler.experiment_cohorts(experiment)).to eq(['facebook'])
      end
    end

    context 'when the experiment has not been added to cohorts' do
      it 'returns an empty list' do
        expect(TestWrangler.experiment_cohorts(experiment)).to be_empty
      end
    end

    context 'when the experiment does not exist' do
      it 'returns false' do
        expect(TestWrangler.experiment_cohorts('random')).to eq(false)
      end
    end
  end

  describe '.remove_experiment(experiment)' do
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

      context 'when the experiment was attached to a cohort' do
        before do
          cohort = TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])
          TestWrangler.save_cohort(cohort)
          TestWrangler.add_experiment_to_cohort(experiment, cohort)
        end

        it "removes the experiment from the cohort" do
          expect{TestWrangler.remove_experiment(experiment)}.to change{TestWrangler.cohort_experiments('facebook')}
        end

        it "deactivates the experiment with the cohort if it was active" do
          TestWrangler.activate_experiment(experiment)
          expect{TestWrangler.remove_experiment(experiment)}.to change{TestWrangler.active_cohort_experiments('facebook')}
        end
      end
    end

    context 'when the experiment does not exist' do
      it 'returns false' do
        expect(TestWrangler.remove_experiment('random')).to eq(false)
      end
    end
  end

  describe '.activate_experiment(experiment)' do
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

    it "activates the experiment with any cohort it belongs to" do
      TestWrangler.save_experiment(experiment)
      cohort = TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])
      TestWrangler.save_cohort(cohort)
      TestWrangler.add_experiment_to_cohort(experiment, cohort)
      expect{TestWrangler.activate_experiment(experiment)}.to change{TestWrangler.active_cohort_experiments(cohort)}
    end
  end

  describe '.deactivate_experiment(experiment)' do
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
    it "deactivates the experiment with any cohort it belongs to" do
      TestWrangler.save_experiment(experiment)
      cohort = TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE'=>'facebook'}}])
      TestWrangler.save_cohort(cohort)
      TestWrangler.add_experiment_to_cohort(experiment, cohort)
      TestWrangler.activate_experiment(experiment)
      expect{TestWrangler.deactivate_experiment(experiment)}.to change{TestWrangler.active_cohort_experiments(cohort)}
    end
  end

  describe '.experiment_active?(experiment_name)' do
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

  describe '.next_variant_for(experiment_name)' do
    context 'when the experiment does not exist' do
      it 'returns false' do
        expect(TestWrangler.next_variant_for('random')).to eq(false)
      end
    end

    context 'when variants have different weights' do
      before do
        experiment = TestWrangler::Experiment.new('facebook_signup', [{a_big_variant: 0.75}, {a_smaller_variant: 0.2}, {a_small_variant: 0.05}])
        TestWrangler.save_experiment(experiment)
        TestWrangler.activate_experiment(experiment)
      end

      context 'when no participants have been registered' do
        it 'picks the highest weighted variant' do
          expect(TestWrangler.next_variant_for('facebook_signup')).to eq('a_big_variant')
        end
      end

      context 'when all variants have proportional participation' do
        before do
          75.times{TestWrangler.increment_experiment_participation('facebook_signup', 'a_big_variant')}
          20.times{TestWrangler.increment_experiment_participation('facebook_signup', 'a_smaller_variant')}
          5.times{TestWrangler.increment_experiment_participation('facebook_signup', 'a_small_variant')}
        end

        it 'picks the highest weighted variant' do
          expect(TestWrangler.next_variant_for('facebook_signup')).to eq('a_big_variant')
        end
      end

      context 'when participation is not balanced' do
        before do
          75.times{TestWrangler.increment_experiment_participation('facebook_signup', 'a_big_variant')}
          20.times{TestWrangler.increment_experiment_participation('facebook_signup', 'a_smaller_variant')}
        end

        it 'picks the variant with the greatest deficit' do
          expect(TestWrangler.next_variant_for('facebook_signup')).to eq('a_small_variant')
        end
      end
    end

    context 'when all variants have the same weight' do
      before do
        experiment = TestWrangler::Experiment.new('facebook_signup', [:variant_1, :variant_2, :variant_3, :variant_4])
        TestWrangler.save_experiment(experiment)
        TestWrangler.activate_experiment(experiment)
      end

      context 'when no participants have been registered' do
        it "picks the first variant" do
          expect(TestWrangler.next_variant_for('facebook_signup')).to eq('variant_1')
        end
      end

      context 'when all variants have equal participation' do
        before do
          4.times{TestWrangler.increment_experiment_participation('facebook_signup', TestWrangler.next_variant_for('facebook_signup'))}
        end

        it "picks the first variant" do
          expect(TestWrangler.next_variant_for('facebook_signup')).to eq('variant_1')
        end
      end

      context 'when participation is unbalanced' do
        before do
          3.times{TestWrangler.increment_experiment_participation('facebook_signup', TestWrangler.next_variant_for('facebook_signup'))}
        end
        it "picks the experiment with the biggest diff" do
          expect(TestWrangler.next_variant_for('facebook_signup')).to eq('variant_4')
        end
      end

    end
  end

  describe '.assignment_for(env)' do
    let(:env){{'QUERY_STRING' => 'UTM_SOURCE=facebook'}}
    
    context 'when the provided request matches an active cohort with active experiments' do
      before do
        cohort = TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE' => 'facebook'}}])
        TestWrangler.save_cohort(cohort)
        experiment = TestWrangler::Experiment.new('facebook_signup', [:control, :signup_on_cya])
        TestWrangler.save_experiment(experiment)
        TestWrangler.activate_experiment(experiment)
        TestWrangler.add_experiment_to_cohort(experiment, cohort)
        TestWrangler.activate_cohort(cohort)
      end

      it "returns a selection hash" do
        expect(TestWrangler.assignment_for(env)).to eq({cohort: 'facebook', experiment: 'facebook_signup', variant: 'control'})
      end

    end

    context 'when the provided request matches no active cohort' do
      it "returns nil" do
        expect(TestWrangler.assignment_for(env)).to be_nil
      end
    end

    context 'when the provided request matches an active cohort which has no active experiments' do      
      before do
        cohort = TestWrangler::Cohort.new('facebook', 0, [{type: :query_parameters, query_parameters: {'UTM_SOURCE' => 'facebook'}}])
        TestWrangler.save_cohort(cohort)
        TestWrangler.activate_cohort(cohort)
      end

      it "returns nil" do
        expect(TestWrangler.assignment_for(env)).to be_nil
      end
    end
  end

  describe '.experiment_participation(experiment_name, variant_name=nil)' do
    before do
      experiment = TestWrangler::Experiment.new('facebook_signup', [:signup_on_cya])
      TestWrangler.save_experiment(experiment)
      TestWrangler.activate_experiment(experiment)
      5.times{ TestWrangler.increment_experiment_participation(experiment, 'signup_on_cya')}
    end
    
    context 'if the experiment does not exist' do
      it "returns false" do
        expect(TestWrangler.experiment_participation('random','random')).to eq(false)
      end
    end

    context 'with no variant' do
      it "returns the participant count for the overall experiment" do
        expect(TestWrangler.experiment_participation('facebook_signup')).to eq(5)
      end
    end

    context 'with a variant specified' do
      context 'when the variant exists' do
        it 'returns the participant count for the variant' do
          expect(TestWrangler.experiment_participation('facebook_signup', 'signup_on_cya')).to eq(5)
        end
      end

      context 'when the variant does not exist' do
        it 'returns false' do
          expect(TestWrangler.experiment_participation('facebook_signup', 'random')).to eq(false)
        end
      end
    end
  end

  describe '.increment_experiment_participation(experiment_name, variant_name)' do
    before do
      experiment = TestWrangler::Experiment.new('facebook_signup', [:signup_on_cya])
      TestWrangler.save_experiment(experiment)
      TestWrangler.activate_experiment(experiment)
    end

    context 'if the experiment does not exist' do
      it "returns false" do
        expect(TestWrangler.increment_experiment_participation('random','random')).to eq(false)
      end
    end

    context 'if the variant does not exist on the experiment' do
      it 'returns false' do
        expect(TestWrangler.increment_experiment_participation('facebook_signup', 'random')).to eq(false)
      end
    end

    context 'if the variant and experiment exist' do
      it 'increments the participation count for the experiment and the variant' do
        expect{TestWrangler.increment_experiment_participation('facebook_signup', 'signup_on_cya')}.to change{TestWrangler.experiment_participation('facebook_signup', 'signup_on_cya')}
      end
    end

  end

end
