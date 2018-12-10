Rails.application.routes.draw do
  devise_for :admins
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  
  resources :quizzes, :schools
  resources :subject_maps, only: [:update]
  get 'quizzes/new/:subject', to: 'quizzes#new'
  get 'leaderboard/(:subject)', to: 'leaderboard#show'
  get 'dashboard/', to: 'dashboard#show'

  get "/pages/*id" => 'pages#show', as: :page, format: false

  # if routing the root path, update for your controller
  root to: 'pages#show', id: 'home'

end
