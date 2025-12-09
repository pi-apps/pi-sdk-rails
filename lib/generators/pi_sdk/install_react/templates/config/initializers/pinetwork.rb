# Initializer for Pi Network engine
#
# You typically use Rails.application.config_for(:pinetwork) to read keys from config/pinetwork.yml
# Use this file for extra Ruby-based logic or secure overrides (e.g., ENV['PI_API_KEY'])

# Example:
# Rails.application.config.x.pi_api_key = ENV['PI_API_KEY'] if ENV['PI_API_KEY'].present?

# Allow hostnames from pinetwork.yml for development/NGROK/Pi integration
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

