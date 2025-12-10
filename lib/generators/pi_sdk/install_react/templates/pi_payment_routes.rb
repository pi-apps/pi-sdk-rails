  # BEGIN PiNetwork::Rails default payment routes
  post '/pi_payment/approve',    to: 'pi_sdk/pi_payment#approve'
  post '/pi_payment/complete',   to: 'pi_sdk/pi_payment#complete'
  post '/pi_payment/cancel',     to: 'pi_sdk/pi_payment#cancel'
  post '/pi_payment/error',      to: 'pi_sdk/pi_payment#error'
  post '/pi_payment/incomplete', to: 'pi_sdk/pi_payment#incomplete'
  get  '/pi_payment/me',         to: 'pi_sdk/pi_payment#me'
  # END PiNetwork::Rails default payment routes
