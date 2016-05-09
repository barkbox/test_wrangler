TestWrangler::Engine.routes.draw do
  namespace :api do
    get 'experiments' => 'experiments#index'
    get 'experiments/:experiment_name' => 'experiments#show'
    post 'experiments/:experiment_name' => 'experiments#update'
    post 'experiments' => 'experiments#create'
  end
end
