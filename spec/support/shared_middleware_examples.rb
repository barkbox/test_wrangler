def process_cookies(cookies)
  Rack::Utils.parse_query(cookies, ';,') { |s| Rack::Utils.unescape(s) rescue s }.each_with_object({}) { |(k,v), hash| hash[k] = Array === v ? v.first : v }
end

shared_examples "it does not modify response cookies" do
  it "should have the same SET_COOKIE value before and after the request" do
    cookies = env['SET_COOKIE']
    status, headers, body = middleware.call(env)
    expect(headers['SET_COOKIE']).to eq(cookies)
  end
end

shared_examples "it sets the env" do
  it "should have a selection set in the env for test_wrangler" do
    expect{middleware.call(env)}.to change{env['test_wrangler']}
  end
end

shared_examples "it unsets the response cookie" do
  it "should set a remove cookie for test_wrangler" do
    status, headers, body = middleware.call(env)
    set_cookie = process_cookies(headers['Set-Cookie'])
    expect(set_cookie).to have_key('test_wrangler')
    expect(set_cookie['test_wrangler']).to eq('')
  end
end

shared_examples "it assigns the response cookie" do |expected|
  it "should add an assignment to SET_COOKIE" do
    cookies = process_cookies(env['HTTP_COOKIE'])
    tw_cookie = cookies['test_wrangler']
    status, headers, body = middleware.call(env)
    set_cookie = process_cookies(headers['Set-Cookie'])
    expect(set_cookie['test_wrangler']).to_not be_blank
    expect(set_cookie['test_wrangler']).to_not eq(tw_cookie)
    if expected
      expect(HashWithIndifferentAccess.new(JSON.parse(Rack::Utils.unescape(set_cookie['test_wrangler'])))).to eq(expected.with_indifferent_access)
    end
  end
end