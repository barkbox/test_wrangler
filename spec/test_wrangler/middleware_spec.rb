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

  context 'if the path is excluded' do
    let(:env){Rack::MockRequest.env_for('https://barkbox.com/api/v2/orders')}
    before do
      TestWrangler.config do |config|
        config.exclude_paths '/api'
      end
    end

    it_behaves_like "it does not modify response cookies"
  end

  context 'if a selection is set in the query parameters' do

    context 'if the indicated experiment is still running' do
      before do
        allow(TestWrangler).to receive(:experiment_active?).with('twitter_oauth'){true}
      end
      let(:env){ Rack::MockRequest.env_for('https://barkbox.com', {'QUERY_STRING' => 'TW_SELECTION=base%3Atwitter_oauth%3Acontrol'}) }

      it_behaves_like "it sets the env"
      it_behaves_like "it assigns the response cookie"

      context 'if a cookie selection is set that is different from the qp' do
        let(:env) do
          json = {"cohort"=>"base", "experiment"=>"facebook_signup", "variant"=>"signup_on_cya"}.to_json
          encoded = Rack::Utils.escape(json)
          Rack::MockRequest.env_for('https://barkbox.com', {'HTTP_COOKIE' => "test_wrangler=#{encoded}", 'QUERY_STRING' => 'TW_SELECTION=base%3Atwitter_oauth%3Acontrol'})
        end
        
        it_behaves_like "it sets the env"
        it_behaves_like "it assigns the response cookie"
      end
    end

    context 'if the indicated experiment has ended or does not exist' do

      let(:env) do
        Rack::MockRequest.env_for('https://barkbox.com', {'QUERY_STRING' => 'TW_SELECTION=base%3Atwitter_oauth%3Acontrol'})
      end

      context 'if other experiments are running for the request cohort' do
        before do
          allow(TestWrangler).to receive(:experiment_active?).with('twitter_oauth'){false}
          allow(TestWrangler).to receive(:assignment_for){{"cohort"=>"base", "experiment"=>"new_copy", "variant"=>"delightful"}}
        end

        it_behaves_like "it sets the env"
        it_behaves_like "it assigns the response cookie"
      end
      
      context 'if no experiments are running for the request cohort' do
        before do
          allow(TestWrangler).to receive(:experiment_active?).with('twitter_oauth'){false}
          allow(TestWrangler).to receive(:assignment_for){nil}
        end
        it_behaves_like "it does not modify response cookies"
      end
    end
  end

  context 'if a test wrangler cookie is set and no qp selection is set' do

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
      it_behaves_like "it sets the env"
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

        it_behaves_like "it sets the env"
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

  context 'if no test wrangler cookie or qp selection is set' do
    let(:env){Rack::MockRequest.env_for('https://barkbox.com')}

    context 'if the request is eligible for enrollment in an active experiment' do
      before do
        allow(TestWrangler).to receive(:assignment_for){{"cohort"=>"base", "experiment"=>"new_copy", "variant"=>"delightful"}}
      end

      it_behaves_like "it sets the env"
      it_behaves_like "it assigns the response cookie"
    end

    context 'if the request is not eligible for enrollment in an active experiment' do
      before do
        allow(TestWrangler).to receive(:assignment_for){nil}
      end

      it_behaves_like "it does not modify response cookies"
    end
  end

  context 'if an error is raised' do
    let(:env){Rack::MockRequest.env_for('https://barkbox.com')}

    before do
      allow(TestWrangler).to receive(:assignment_for){raise Redis::BaseError}
    end

    it_behaves_like "it does not modify response cookies"

    context 'if a logger is set in the config' do
      before do
        @logger = Logger.new(STDOUT)
        TestWrangler.config do |config|
          config.logger @logger
        end
      end

      it 'logs the error' do
        expect(@logger).to receive(:error).with(Redis::BaseError)
        middleware.call(env)
      end
    end
  end
end
