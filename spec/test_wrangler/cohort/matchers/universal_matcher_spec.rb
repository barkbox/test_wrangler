require 'rails_helper'

describe TestWrangler::Cohort::Matchers::UniversalMatcher do
  let(:matcher){TestWrangler::Cohort::Matchers::UniversalMatcher.new()}
  
  describe '::new(rules=nil)' do
    it 'accepts any input for rules but always sets an empty array' do
      expect(matcher).to be_a(TestWrangler::Cohort::Matchers::UniversalMatcher)
      expect(matcher.rules.length).to eq(0)
      crazy_matcher = TestWrangler::Cohort::Matchers::UniversalMatcher.new(['some', /stuff/])
      expect(crazy_matcher).to be_a(TestWrangler::Cohort::Matchers::UniversalMatcher)
      expect(crazy_matcher.rules.length).to eq(0)
    end
  end

  describe '#match?(env)' do
    it 'will match any request' do
      ['what', {}, []].each do |req|
        expect(matcher.match?(req)).to eq(true)
      end
    end
  end

end
