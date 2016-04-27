require 'rails_helper'
require 'support/shared_middleware_examples'

describe TestWrangler::Middleware do
  let(:app){ ->(env){ [200, env, "app"] } }
  let(:middleware){ TestWrangler::Middleware.new(app) }
  before do
    allow(TestWrangler).to receive(:active?){true}
  end

  context 'if no tests are running' do
    before do
      allow(TestWrangler).to receive(:active?){false}
    end

    let(:env){Rack::MockRequest.env_for('https://barkbox.com')}
    it_behaves_like "it does not modify response cookies"
  end

  context 'if a test wrangler cookie is set' do

    context 'if the indicated experiment is still running' do
      before do
        allow(TestWrangler).to receive(:experiment_active?).with('facebook_signup'){true}
      end
      let(:env) do
        json = {"cohort"=>"base", "experiment"=>"facebook_signup", "variant"=>"signup_on_cya"}.to_json
        encoded = Rack::Utils.escape(json)
        Rack::MockRequest.env_for('https://barkbox.com', {'HTTP_COOKIE' => "test_wrangler=#{encoded}"})
      end
      it_behaves_like "it does not modify response cookies"
    end

    context 'if the indicated experiment has ended or does not exist' do

      let(:env) do
        json = {"cohort"=>"base", "experiment"=>"facebook_signup", "variant"=>"signup_on_cya"}.to_json
        encoded = Rack::Utils.escape(json)
        Rack::MockRequest.env_for('https://barkbox.com', {'HTTP_COOKIE' => "test_wrangler=#{encoded}"})
      end

      context 'if other experiments are running for the request cohort' do
        before do
          allow(TestWrangler).to receive(:experiment_active?).with('facebook_signup'){false}
          allow(TestWrangler).to receive(:assignment_for){{"cohort"=>"base", "experiment"=>"new_copy", "variant"=>"delightful"}}
        end

        it_behaves_like "it assigns the response cookie"
      end
      context 'if no experiments are running for the request cohort' do
        before do
          allow(TestWrangler).to receive(:experiment_active?).with('facebook_signup'){false}
          allow(TestWrangler).to receive(:assignment_for){nil}
        end
        it_behaves_like "it unsets the response cookie"
      end
    end
  end

  context 'if no test wrangler cookie is set' do
    let(:env){Rack::MockRequest.env_for('https://barkbox.com')}
    
    context 'if the request is eligible for enrollment in an active experiment' do
      before do
        allow(TestWrangler).to receive(:assignment_for){{"cohort"=>"base", "experiment"=>"new_copy", "variant"=>"delightful"}}
      end

      it_behaves_like "it assigns the response cookie"
    end
    context 'if the request is not eligible for enrollment in an active experiment' do
      before do
        allow(TestWrangler).to receive(:assignment_for){nil}
      end

      it_behaves_like "it does not modify response cookies"
    end
  end
end
