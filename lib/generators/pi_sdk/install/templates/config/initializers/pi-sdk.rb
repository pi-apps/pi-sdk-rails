# Initializer for Pi SDK engine
#
# You typically use Rails.application.config_for(:pisdk) to read keys from config/pisdk.yml
# Use this file for extra Ruby-based logic or secure overrides (e.g., ENV['PI_API_KEY'])

# Example:
# Rails.application.config.x.pi_api_key = ENV['PI_API_KEY'] if ENV['PI_API_KEY'].present?

# Allow hostnames from pi-sdk.yml for development/NGROK/Pi integration
begin
  hostnames = ::Rails.application.config_for(:pi_sdk)['hostnames']
  if hostnames.present?
    cfg_hosts = Rails.application.config.hosts
    hostnames.each do |host|
      host.strip!
      cfg_hosts << host unless cfg_hosts.include?(host)
    end
  end
rescue => e
  warn "[pi-sdk-rails] Could not parse hostnames from pi-sdk.yml: #{e}"
end

Rails.application.config.action_dispatch.default_headers.merge!({
  'X-Frame-Options' => 'ALLOWALL'
})
