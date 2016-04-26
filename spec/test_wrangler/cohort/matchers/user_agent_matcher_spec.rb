require 'rails_helper'

describe TestWrangler::Cohort::Matchers::UserAgentMatcher do
  let(:matcher){TestWrangler::Cohort::Matchers::UserAgentMatcher.new(['Mobile user agent', /Mobile/])}
  describe '::new(*rules)' do
    it 'accepts an array of strings and/or regexps to set as matching rules' do
      expect(matcher).to be_a(TestWrangler::Cohort::Matchers::UserAgentMatcher)
      expect(matcher.rules.length).to eq(2)
    end
  end

  describe '#match?(env)' do
    context 'with string rules' do
      it 'will match if the user agent is exactly equal to the string' do
        matcher = TestWrangler::Cohort::Matchers::UserAgentMatcher.new(['Mobile user agent'])
        expect(matcher).to be_match({'HTTP_USER_AGENT' => 'Mobile user agent'})
        expect(matcher).to_not be_match('Mobile')
      end
    end

    context 'with regexp rules' do
      it 'will return true if all regexps =~ the user agent string' do
        matcher = TestWrangler::Cohort::Matchers::UserAgentMatcher.new([/Mobile/, /ag/, /^[A-Z]\w+\s\w+\s\w+$/])
        expect(matcher).to be_match({'HTTP_USER_AGENT' => 'Mobile user agent'})
        expect(matcher).to_not be_match({'HTTP_USER_AGENT' => 'Something matching aglmostallofthecriteria'})
      end
    end

    context 'with mixed rules' do
      it 'will return true if all rules match and false if any do not' do
        expect(matcher).to be_match({'HTTP_USER_AGENT' => 'Mobile user agent'})
        expect(matcher).to_not be_match('Mobile')
      end
    end
  end
end
