Rails.application.routes.draw do

  devise_for :users, controllers: { sessions: "sessions" },
    path: '', path_names: { sign_in: 'login', sign_out: 'logout' }
  resources :users
  root 'pages#home'
  get '/help', to: 'pages#help'
  get '/signup', to: 'users#new'

  get 'password_resets/new'
  get 'password_resets/edit'
  get 'sessions/new'
  get 'users/new'
  get 'users/edit'
  
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
