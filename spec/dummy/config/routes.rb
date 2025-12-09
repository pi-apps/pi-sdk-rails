Rails.application.routes.draw do
  resources :users
  get "home/index"
  get "home/reactdemo"
  root to: "home#index"
  mount Pinetwork::Rails::Engine => "/pinetwork-rails"
  # Direct mapping to engine pi_payment controller actions for override/testing:
  post '/pi_payment/approve', to: 'pinetwork/rails/pi_payment#approve'
  post '/pi_payment/complete', to: 'pinetwork/rails/pi_payment#complete'
  post '/pi_payment/cancel',   to: 'pinetwork/rails/pi_payment#cancel'
  post '/pi_payment/error',    to: 'pinetwork/rails/pi_payment#error'
  post '/pi_payment/incomplete', to: 'pinetwork/rails/pi_payment#incomplete'
  get  '/pi_payment/me',       to: 'pinetwork/rails/pi_payment#me'
end
