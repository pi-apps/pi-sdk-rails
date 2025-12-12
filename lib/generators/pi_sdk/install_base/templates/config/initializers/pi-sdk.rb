# config/initializers/pi_sdk.rb
#
# Loosen frame-embedding (X-Frame-Options) for Pi Browser and local Pi Sandbox testing.
# In production, consider restricting allowed origins for better security.
if Rails.env.development? || Rails.env.test?
  Rails.application.config.action_dispatch.default_headers.delete('X-Frame-Options')
  Rails.application.config.action_dispatch.default_headers['X-Frame-Options'] = 'ALLOWALL'
end


