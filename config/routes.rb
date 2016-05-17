TestWrangler::Engine.routes.draw do
  namespace :api do
    get 'experiments' => 'experiments#index'
    get 'experiments/:experiment_name' => 'experiments#show'
    post 'experiments/:experiment_name' => 'experiments#update'
    put 'experiments/:experiment_name' => 'experiments#update'
    post 'experiments' => 'experiments#create'
    delete 'experiments/:experiment_name' => 'experiments#destroy'

    get 'cohorts' => 'cohorts#index'
    get 'cohorts/:cohort_name' => 'cohorts#show'
    post 'cohorts/:cohort_name' => 'cohorts#update'
    put 'cohorts/:cohort_name' => 'cohorts#update'
    post 'cohorts' => 'cohorts#create'
    delete 'cohorts/:cohort_name' => 'cohorts#destroy'
  end

  namespace :dashboard do
    get '(*any)' => 'base#bootstrap'
  end
end
