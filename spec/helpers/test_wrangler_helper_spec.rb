require 'rails_helper'
require 'test_wrangler/helper'

describe TestWrangler::Helper do
  
  describe '#test_wrangler_selection' do
    context 'when no selection is set in the cookies' do
      it 'returns a blank selection' do
        expect(helper.test_wrangler_selection).to eq({cohort: nil, experiment: nil, variant: nil}.with_indifferent_access)
      end
    end

    context 'when a selection is set in the request cookies' do
      before do
        @request.cookies['test_wrangler'] = Rack::Utils.escape(JSON.generate({cohort: 'base', experiment: 'facebook_signup', variant: 'control'}))
      end

      it 'returns the selection from the cookies' do
        expect(helper.test_wrangler_selection).to eq(HashWithIndifferentAccess.new({cohort: 'base', experiment: 'facebook_signup', variant: 'control'}))
      end
    end

    context 'when a selection is set in the env' do
      before do
        @request.env['test_wrangler'] = {cohort: 'base', experiment: 'facebook_signup', variant: 'control'}
      end

      it 'returns the selection from the cookies' do
        expect(helper.test_wrangler_selection).to eq(HashWithIndifferentAccess.new({cohort: 'base', experiment: 'facebook_signup', variant: 'control'}))
      end
    end
  end

  describe '#complete_experiment' do
    context 'when no selection is set in the cookies' do
      it 'returns a blank selection' do
        expect(helper.complete_experiment).to eq({cohort: nil, experiment: nil, variant: nil}.with_indifferent_access)
      end
    end

    context 'when a selection is set in the cookies' do
      before do
        @request.cookies['test_wrangler'] = JSON.generate({cohort: 'base', experiment: 'facebook_signup', variant: 'control'})
      end
      
      it 'returns the selection' do
        expect(helper.complete_experiment).to eq(HashWithIndifferentAccess.new({cohort: 'base', experiment: 'facebook_signup', variant: 'control'}))
      end

      it 'unsets the cookie' do
        expect{helper.complete_experiment}.to change{helper.cookies['test_wrangler']}.to(nil)
      end
    end
  end

end
