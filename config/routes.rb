TestWrangler::Engine.routes.draw do
  namespace :api do
    get 'experiments' => 'experiments#index'
    get 'experiments/:experiment_name' => 'experiments#show'
    post 'experiments/:experiment_name' => 'experiments#update'
    post 'experiments' => 'experiments#create'
    delete 'experiments/:experiment_name' => 'experiments#destroy'
  end
end
