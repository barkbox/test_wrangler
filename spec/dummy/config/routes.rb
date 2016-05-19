Rails.application.routes.draw do
  mount TestWrangler::Engine => "/test_wrangler"
end
