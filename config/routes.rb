Rails.application.routes.draw do
  get 'session/home'
  get 'session/help'
  devise_for :users, controllers: { sessions: "sessions" }
  resources :users
  root 'session#home'
  get '/signup', to: 'users#new'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
