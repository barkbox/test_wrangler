require 'rails_helper'

describe TestWrangler::Cohort::Matchers::CookiesMatcher do
  let(:matcher){TestWrangler::Cohort::Matchers::CookiesMatcher.new([{'UTM_SOURCE'=>'facebook','UTM_CAMPAIGN'=>'i_love_cookies'},{'UTM_SERIALIZED' => 'facebook:i_love_cookies'}])}
  
  describe '::new(*rules)' do
    it 'accepts an array of hashes representing sets of cookie values to match' do
      expect(matcher).to be_a(TestWrangler::Cohort::Matchers::CookiesMatcher)
      expect(matcher.rules.length).to eq(2)
    end
  end

  describe '#match?(env)' do
    context 'with a single rule' do
      it 'returns true if the request matches all of the provided cookie values' do
        matcher = TestWrangler::Cohort::Matchers::CookiesMatcher.new([{'UTM_SOURCE'=>'facebook','UTM_CAMPAIGN'=>'i_love_cookies'}])
        expect(matcher).to be_match({'HTTP_COOKIE' => 'UTM_SOURCE=facebook; UTM_CAMPAIGN=i_love_cookies'})
      end

      it 'returns false if any of the cookie values do not match' do
        matcher = TestWrangler::Cohort::Matchers::CookiesMatcher.new([{'UTM_SOURCE'=>'facebook','UTM_CAMPAIGN'=>'i_love_cookies'}])
        expect(matcher).to_not be_match({'HTTP_COOKIE' => 'UTM_SOURCE=facebook; UTM_CAMPAIGN=i_love_cookie'})
      end
    end

    context 'with multiple rules' do
      it 'returns true if any rule is fully matched by the cookies' do
        expect(matcher).to be_match({'HTTP_COOKIE' => 'UTM_SOURCE=facebook; UTM_CAMPAIGN=i_love_cookies'})
        expect(matcher).to be_match({'HTTP_COOKIE' => 'UTM_SERIALIZED=facebook:i_love_cookies'})
      end
    end
  end
end
