require 'rails_helper'

describe TestWrangler::Cohort do
  describe '::new(name, criteria)' do
    it 'instantiates a new cohort with the given name and filtering criteria' do
      expect(TestWrangler::Cohort.new('mobile', [{type: :user_agent, user_agent: /Mobi/}])).to be_a(TestWrangler::Cohort)
    end

    describe 'criteria' do
      context 'when all criteria correspond to existing matchers' do
        it 'instantiates matchers of the appropriate class' do
          cohort = TestWrangler::Cohort.new('mobile', [{type: :user_agent, user_agent: /Mobi/}])
          expect(cohort.criteria.first).to be_a(TestWrangler::Cohort::Matchers::UserAgentMatcher)
        end
      end

      context 'when the criteria does not correspond to an existing matcher' do
        it 'throws an error' do
          expect{TestWrangler::Cohort.new('mobile', [{type: :some_matcher, some_matcher: 'hey'}])}.to raise_error(NoMethodError)
        end
      end
    end 

    describe 'match?(env)' do
      context 'when all matchers return true for the given request' do
        it 'returns true' do
          cohort = TestWrangler::Cohort.new('mobile', [{type: :user_agent, user_agent: [/Mobi/, /brows/]}])
          expect(cohort).to be_match({'HTTP_USER_AGENT' => 'Mobile browser'})
        end
      end

      context 'when any matcher returns false for the given request' do
        it 'returns false' do
          cohort = TestWrangler::Cohort.new('mobile', [{type: :user_agent, user_agent: [/Mobi/, /snuffle/]}])
          expect(cohort).to_not be_match({'HTTP_USER_AGENT' => 'Mobile browser'})
        end
      end
    end 
  end
end
