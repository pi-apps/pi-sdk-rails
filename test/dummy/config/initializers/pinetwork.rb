# Sample Pi Network API key initializer for the engine
# Make sure you have a config/pinetwork.yml like:
#
# development:
#   api_key: YOUR_DEVELOPMENT_PI_API_KEY
# production:
#   api_key: YOUR_PRODUCTION_PI_API_KEY
#
# The controller will read the value via Rails.application.config_for(:pinetwork)['api_key']
# NEVER commit real API keys to public repositories!
begin
  hostnames = ::Rails.application.config_for(:pinetwork)['hostnames']
  if hostnames.present?
    cfg_hosts = Rails.application.config.hosts
    hostnames.each do |host|
      host.strip!
      cfg_hosts << host unless cfg_hosts.include?(host)
    end
  end
rescue => e
  warn "[pinetwork-rails] Could not parse hostnames from pinetwork.yml: #{e}"
end

Rails.application.config.action_dispatch.default_headers.merge!({
  'X-Frame-Options' => 'ALLOWALL'
})


