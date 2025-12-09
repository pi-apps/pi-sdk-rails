  # BEGIN PiNetwork::Rails default payment routes
  post '/pi_payment/approve',    to: 'pi-sdk-rails/pi_payment#approve'
  post '/pi_payment/complete',   to: 'pi-sdk-rails/pi_payment#complete'
  post '/pi_payment/cancel',     to: 'pi-sdk-rails/pi_payment#cancel'
  post '/pi_payment/error',      to: 'pi-sdk-rails/pi_payment#error'
  post '/pi_payment/incomplete', to: 'pi-sdk-rails/pi_payment#incomplete'
  get  '/pi_payment/me',         to: 'pi-sdk-rails/pi_payment#me'
  # END PiNetwork::Rails default payment routes
