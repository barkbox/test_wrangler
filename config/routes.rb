TestWrangler::Engine.routes.draw do
  namespace :api do
    resources :experiments
  end
end
