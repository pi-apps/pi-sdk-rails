Rails.application.routes.draw do
  resources :users
  get "home/index"
  get "home/reactdemo"
  root to: "home#index"
  mount PiSdk::Engine => "/pi-sdk-rails"
  # Direct mapping to engine pi_payment controller actions for override/testing:
  post '/pi_payment/approve', to: 'pi_sdk/pi_payment#approve'
  post '/pi_payment/complete', to: 'pi_sdk/pi_payment#complete'
  post '/pi_payment/cancel',   to: 'pi_sdk/pi_payment#cancel'
  post '/pi_payment/error',    to: 'pi_sdk/pi_payment#error'
  post '/pi_payment/incomplete', to: 'pi_sdk/pi_payment#incomplete'
  get  '/pi_payment/me',       to: 'pi_sdk/pi_payment#me'
end
