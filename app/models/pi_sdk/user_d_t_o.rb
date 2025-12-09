# frozen_string_literal: true
require 'net/http'
require 'uri'
require 'json'

module PiSdk
  module ApiConfig
    def api_config
      ::Rails.application.config_for(:pinetwork)
    end
    def api_url_base;   api_config['api_url_base'];   end
    def api_version;    api_config['api_version'];    end
    def api_controller; api_config['api_controller']; end
    def api_key;        api_config['api_key'];        end
  end

  # UserDTO encapsulates a Pi Network user as returned from /v2/me API.
  # Not an ActiveRecord model; plain Ruby object.
  #
  # Example usage:
  #   user = PiSdk::UserDTO.get(access_token)
  #   return unless user
  #   puts user.uid, user.username, user.scope_list
  class UserDTO
    extend ApiConfig
    attr_reader :uid, :credentials, :username

    # Create a DTO from API hash
    # @param [Hash] data
    def initialize(data)
      @uid         = data['uid']
      @credentials = data['credentials'] || {}
      @username    = data['username']
    end

    # List of granted scopes
    # @return [Array<String>]
    def scope_list
      credentials['scopes'] || []
    end

    # Credentials expiration timestamp
    # @return [Integer, nil]
    def valid_until_timestamp
      credentials.dig('valid_until', 'timestamp')
    end

    # Credentials expiration ISO8601
    # @return [String, nil]
    def valid_until_iso8601
      credentials.dig('valid_until', 'iso8601')
    end

    # Returns a DateTime object for the credentials' validity.
    # Prefers iso8601 if present, otherwise falls back to timestamp.
    # @return [DateTime, nil] Returns nil if validity info is absent or invalid.
    def valid_until
      iso = valid_until_iso8601
      if iso && !iso.empty?
        begin
          return DateTime.iso8601(iso)
        rescue ArgumentError
        end
      end
      ts = valid_until_timestamp
      return DateTime.strptime(ts.to_s, '%s') if ts
      nil
    end

    # Class method to fetch UserDTO from Pi API with access_token
    # @param [String] access_token
    # @return [UserDTO, nil]
    def self.get(access_token)
      uri = URI.parse("#{api_url_base}/#{api_version}/me")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      req = Net::HTTP::Get.new(uri.path, { 'Authorization' => "Bearer #{access_token}" })
      resp = http.request(req)
      return nil unless resp.is_a?(Net::HTTPSuccess)
      begin
        json = JSON.parse(resp.body)
        new(json)
      rescue JSON::ParserError
        nil
      end
    rescue StandardError => e
      warn "[UserDTO] Error fetching user: #{e}"
      nil
    end
  end
end
