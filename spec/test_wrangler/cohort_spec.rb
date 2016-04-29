require 'rails_helper'

describe TestWrangler::Cohort do
  describe '::new(name, priority, criteria)' do
    it 'instantiates a new cohort with the given name and filtering criteria' do
      expect(TestWrangler::Cohort.new('mobile', 0, [{type: :user_agent, user_agent: /Mobi/}])).to be_a(TestWrangler::Cohort)
    end
  end

  describe '#critera' do
    context 'first call' do
      it 'evaluates the original criteria into matchers' do
        cohort = TestWrangler::Cohort.new('mobile', 0, [{type: :user_agent, user_agent: [/Mobi/, /brows/]}])
        expect{cohort.criteria}.to change{cohort.instance_variable_get(:@criteria)}.from(nil).to(Array)
      end

      it 'raises an error if any of the matcher types are not valid' do
        cohort = TestWrangler::Cohort.new('mobile', 0, [{type: :some_matcher, user_agent: [/Mobi/, /brows/]}])
        expect{cohort.criteria}.to raise_error(NoMethodError)
      end
    end
  end

  describe '#match?(env)' do
    context 'when any matchers return true for the given request' do
      it 'returns true' do
        cohort = TestWrangler::Cohort.new('mobile', 0, [{type: :user_agent, user_agent: [/Mobi/, /brows/]}])
        expect(cohort).to be_match({'HTTP_USER_AGENT' => 'Mobile browser'})
      end
    end

    context 'when all matchers return false for the given request' do
      it 'returns false' do
        cohort = TestWrangler::Cohort.new('mobile', 0, [{type: :user_agent, user_agent: [/Mobi/, /snuffle/]}])
        expect(cohort).to_not be_match({'HTTP_USER_AGENT' => 'Mobile browser'})
      end
    end
  end

  describe '==(other)' do
    it 'returns true if the other object is a Cohort and #serialize is equivalent' do
      cohort = TestWrangler::Cohort.new('mobile', 0, [{type: :user_agent, user_agent: [/Mobi/, /snuffle/]}])
      cohort2 = TestWrangler::Cohort.new('mobile', 0, [{type: :user_agent, user_agent: [/Mobi/, /snuffle/]}])
      expect(cohort == cohort2).to eq(true)
    end
  end

  describe 'hash' do
    it 'uses the hash of the serialized version of the cohort to establish equivalence' do
      cohort = TestWrangler::Cohort.new('mobile', 0, [{type: :user_agent, user_agent: [/Mobi/, /snuffle/]}])
      cohort2 = TestWrangler::Cohort.new('mobile', 0, [{type: :user_agent, user_agent: [/Mobi/, /snuffle/]}])
      expect(cohort.hash).to eq(cohort2.hash)
    end
  end

  describe '#serialize' do
    it "outputs a data structure that can be used for persistence" do
      cohort = TestWrangler::Cohort.new('mobile', 0, [{type: :user_agent, user_agent: [/Mobi/, /snuffle/]}, {type: :cookies, cookies: [{'this' => 'that'}]}])
      expected = ['mobile', 0, [{'type' => 'user_agent', 'user_agent' => [/Mobi/, /snuffle/]}.to_json, {'type' => 'cookies', 'cookies' => [{'this' => 'that'}]}.to_json ]]
      expect(cohort.serialize).to eq(expected)
    end
  end

  describe "::deserialize(data)" do
    it "accepts serialized cohort data and returns a cohort" do
      cohort = TestWrangler::Cohort.new('mobile', 0, [{type: :user_agent, user_agent: [/Mobi/, /snuffle/]}, {type: :cookies, cookies: [{'this' => 'that'}]}])
      cohort2 = TestWrangler::Cohort.deserialize(cohort.serialize)
      expect(cohort).to eq(cohort2)
    end
  end
end
