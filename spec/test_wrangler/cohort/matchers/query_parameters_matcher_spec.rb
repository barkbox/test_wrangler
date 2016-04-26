require 'rails_helper'

describe TestWrangler::Cohort::Matchers::QueryParametersMatcher do
  let(:matcher){TestWrangler::Cohort::Matchers::QueryParametersMatcher.new([{'UTM_SOURCE'=>'facebook','UTM_CAMPAIGN'=>'i_love_cookies'},{'UTM_SERIALIZED' => 'facebook:i_love_cookies'}])}
  describe '::new(*rules)' do
    it 'accepts an array of hashes representing sets of query parameters to match' do
      expect(matcher).to be_a(TestWrangler::Cohort::Matchers::QueryParametersMatcher)
      expect(matcher.rules.length).to eq(2)
    end
  end

  describe '#match?(env)' do
    context 'with a single rule' do
      it 'returns true if the request matches all of the provided query parameters' do
        matcher = TestWrangler::Cohort::Matchers::QueryParametersMatcher.new([{'UTM_SOURCE'=>'facebook','UTM_CAMPAIGN'=>'i_love_cookies'}])
        expect(matcher).to be_match({'QUERY_STRING' => 'UTM_SOURCE=facebook&UTM_CAMPAIGN=i_love_cookies'})
      end

      it 'returns false if any of the query parameters do not match' do
        matcher = TestWrangler::Cohort::Matchers::QueryParametersMatcher.new([{'UTM_SOURCE'=>'facebook','UTM_CAMPAIGN'=>'i_love_cookies'}])
        expect(matcher).to_not be_match({'QUERY_STRING' => 'UTM_SOURCE=facebook&UTM_CAMPAIGN=i_love_cookie'})
      end
    end

    context 'with multiple rules' do
      it 'returns true if any rule is fully matched by the query string' do
        expect(matcher).to be_match({'QUERY_STRING' => 'UTM_SOURCE=facebook&UTM_CAMPAIGN=i_love_cookies'})
        expect(matcher).to be_match({'QUERY_STRING' => 'UTM_SERIALIZED=facebook:i_love_cookies'})
      end
    end
  end
end
