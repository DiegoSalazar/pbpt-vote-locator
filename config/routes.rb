Rails.application.routes.draw do
  resources :locators, only: :create
  root to: 'visitors#index'
end
