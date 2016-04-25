require 'rails_helper'
require 'support/redis'

describe TestWrangler::Experiment do
  describe '::new(name, variants=[])' do
    context 'with only a name' do
      it 'instantiates an experiment whose only variant has the same name as the experiment' do
        experiment = TestWrangler::Experiment.new('my_great_experiment')
        expect(experiment.variants.keys.length).to eq(1)
        expect(experiment.variants.keys.first).to eq('my_great_experiment')
      end
    end
    context 'with specified variants' do
      it 'does not automatically create a variant with the same name as the experiment' do
        experiment = TestWrangler::Experiment.new('my_great_experiment', [:alternative_1])
        expect(experiment.variants.keys.length).to eq(1)
        expect(experiment.variants.keys.first).to eq('alternative_1')
      end

      context 'with only variant names' do
        context 'with an even number of variants' do
          it 'assigns an equal weight to each variant' do
            experiment = TestWrangler::Experiment.new('my_great_experiment', [:alternative_1, :alternative_2, :alternative_3])
            expect(experiment.variants.length).to eq(3)
            expect(experiment.variants.all?{|k,v| v == 1.0/3.0}).to eq(true)
          end
        end
      end

      context 'with variant names and weights' do
        context 'when all variant weights are specified' do
          context 'when weights add to more than one' do
            it 'normalizes weights to fractions of 1' do
              experiment = TestWrangler::Experiment.new('my_great_experiment', [{alternative_1: 4} , {alternative_2: 5} , {alternative_3: 6}])
              expect(experiment.variants.values.inject(0){|sum, weight| sum += weight }).to eq(1)
              expect(experiment.variants[:alternative_1]).to eq(4.0/15.0)
              expect(experiment.variants[:alternative_2]).to eq(5.0/15.0)
              expect(experiment.variants[:alternative_3]).to eq(6.0/15.0)
            end
          end
          context 'when weights add to exactly one' do
            it 'honors the specified weights' do
              experiment = TestWrangler::Experiment.new('my_great_experiment', [{alternative_1: 0.5} , {alternative_2: 0.5}])
              expect(experiment.variants[:alternative_1]).to eq(0.5)
              expect(experiment.variants[:alternative_2]).to eq(0.5)
            end
          end
        end
        context 'when only some variant weights are specified' do
          context 'when the weights add to less than one' do
            it "splits the remaining weight among the variants with unspecified weight" do
              experiment = TestWrangler::Experiment.new('my_great_experiment', [{alternative_1: 0.5} , :alternative_2, :alternative_3])
              expect(experiment.variants[:alternative_1]).to eq(0.5)
              expect(experiment.variants[:alternative_2]).to eq(0.25)
              expect(experiment.variants[:alternative_3]).to eq(0.25)
            end
          end
          context 'when the sum of the weights is greater than or equal to one' do
            it "assigns the smallest specified weight to all unspecified variants, then normalizes weights to fractions of one" do
              experiment = TestWrangler::Experiment.new('my_great_experiment', [{alternative_1: 0.5}, {alternative_2: 0.5}, :alternative_3, {alternative_4: 0.25}])
              expect(experiment.variants[:alternative_1]).to eq(1.0/3.0)
              expect(experiment.variants[:alternative_2]).to eq(1.0/3.0)
              expect(experiment.variants[:alternative_3]).to eq(0.25/1.5)
              expect(experiment.variants[:alternative_4]).to eq(0.25/1.5)
            end
          end
        end
      end
    end
  end

  describe "#serialize" do
    it "outputs a datastructure that can be used for persistence" do
      experiment = TestWrangler::Experiment.new('my_great_experiment', [{alternative_1: 0.5}, {alternative_2: 0.5}, :alternative_3, {alternative_4: 0.25}])
      expected = ['my_great_experiment', {'alternative_1' => 1.0/3.0, 'alternative_2' => 1.0/3.0, 'alternative_3' => 0.25/1.5, 'alternative_4' => 0.25/1.5}]
      expect(experiment.serialize).to eq(expected)
    end
  end

  describe "::deserialize(data)" do
    it "accepts serialized experiment data and returns an experiment" do
      experiment = TestWrangler::Experiment.new('my_great_experiment', [{alternative_1: 0.5}, {alternative_2: 0.5}, :alternative_3, {alternative_4: 0.25}])
      experiment2 = TestWrangler::Experiment.deserialize(experiment.serialize)
      expect(experiment).to eq(experiment2)
    end
  end
end