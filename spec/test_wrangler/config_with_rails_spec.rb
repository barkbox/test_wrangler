require 'rails_helper'

describe TestWrangler::Config do
  let(:config){TestWrangler::Config.new}
  context 'with Rails' do
    describe '#experiments_directory(dirname=nil)' do
      context 'with an argument' do
        it 'sets the path for the experiments directory' do
          config.experiments_directory('/some/directory/somewhere')
          expect(config.experiments_directory).to eq('/some/directory/somewhere')
        end
      end
      
      context 'without an argument' do
        it 'returns nil' do
          expect(config.experiments_directory).to eq(Rails.root.join('config','test_wrangler','experiments'))
        end
      end
    end

    describe '#cohorts_directory(dirname=nil)' do
      context 'with an argument' do
        it 'sets the path for the cohorts directory' do
          config.cohorts_directory('/some/directory/somewhere')
          expect(config.cohorts_directory).to eq('/some/directory/somewhere')
        end
      end
      
      context 'without an argument' do
        it 'returns nil' do
          expect(config.cohorts_directory).to eq(Rails.root.join('config','test_wrangler','cohorts'))
        end
      end
    end

  end
end