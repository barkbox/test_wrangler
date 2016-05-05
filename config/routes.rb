TestWrangler::Engine.routes.draw do
  namespace :api do
    get 'experiments' => 'experiments#index'
    get 'experiments/:experiment_name' => 'experiments#show'
  end
end
