Rails.application.routes.draw do
  get 'session/home'
  get 'session/help'
  devise_for :users, controllers: { sessions: "sessions" }
  resources :users
  root 'session#home'
  get '/signup', to: 'users#new'

  get 'password_resets/new'
  get 'password_resets/edit'
  get 'session/new'
  get 'users/new'
  get 'users/edit'
  
  
  get '/help', to: 'session#help'
  get '/about', to: 'session#about'
  get '/contact', to: 'session#contact'
  get '/signup', to: 'users#new'
  post '/signup', to: 'users#create'
  get '/login', to: 'session#new'
  post '/login', to: 'session#create'
  delete '/logout', to: 'session#destroy'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
