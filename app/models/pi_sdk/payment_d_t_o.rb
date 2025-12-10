# frozen_string_literal: true
require 'date'
require 'bigdecimal'
require 'net/http'
require 'uri'
require 'json'

module PiSdk
  module ApiConfig
    def api_config
      ::Rails.application.config_for(:pi_sdk)
    end
    def api_url_base;   api_config['api_url_base'];   end
    def api_version;    api_config['api_version'];    end
    def api_controller; api_config['api_controller']; end
    def api_key;        api_config['api_key'];        end
  end

  # PaymentDTO is a plain Ruby value object representing a Pi payment as returned by the Pi API.
  # Not an ActiveRecord model. Wraps all known fields, handling missing/nulls robustly.
  #
  # API endpoint/configuration (URL base, version, controller, API key) is always read from config/pinetwork.yml at runtime.
  # The .get(payment_id) class method fetches payment info directly from the Pi API using these config values.
  class PaymentDTO
    extend ApiConfig
    attr_reader :identifier, :user_uid, :amount, :description, :metadata, :username, :transaction, :error, :completed_at, :cancelled_at

    # @param [Hash] data Pi API payment hash (see docs)
    def initialize(data)
      @identifier   = data['identifier']
      @user_uid     = data['user_uid']
      @amount       = data['amount']
      @status       = data['status'] || {}
      @description  = data['description']
      @metadata     = data['metadata'] || {}
      @_created_at  = data['created_at']
      @created_at = if @_created_at && !@_created_at.empty?
                      begin
                        DateTime.iso8601(@_created_at)
                      rescue ArgumentError
                        nil
                      end
                    else
                      nil
                    end
      @completed_at = data['completed_at'] || {}
      @cancelled_at = data['cancelled_at'] || {}
      @transaction  = data['transaction'] || {}
      @username     = data['username']
      @error        = data['error']
    end

    # Preferred initializer
    # @param [Hash] data
    # @return [PaymentDTO]
    def self.from_api(data)
      new(data)
    end

    # Status booleans as provided
    # @return [Boolean]
    def developer_approved?    ; !!@status['developer_approved'];    end
    def transaction_verified?  ; !!@status['transaction_verified'];  end
    def developer_completed?   ; !!@status['developer_completed'];   end
    def cancelled?             ; !!@status['cancelled'];            end
    def user_cancelled?        ; !!@status['user_cancelled'];       end

    # Returns one of :cancelled, :completed, :verified, :approved, or :pending
    # Priority order: cancelled > completed > verified > approved > pending
    # @return [Symbol]
    def summary_status
      return :cancelled if cancelled? || user_cancelled?
      return :completed if developer_completed?
      return :verified  if transaction_verified?
      return :approved  if developer_approved?
      :pending
    end

    # @return [DateTime, nil] created_at as DateTime or nil
    def created_at
      @created_at
    end

    # Amount as BigDecimal
    # @return [BigDecimal, nil]
    def amount_decimal
      return nil if amount.nil? || amount.to_s.empty?
      BigDecimal(amount.to_s)
    rescue ArgumentError
      nil
    end

    # Transaction helpers
    # @return [String, nil]
    def txid; transaction['txid']; end
    # @return [Integer, nil]
    def block_number; transaction['block_number']; end
    # @return [String, nil]
    def blockchain; transaction['blockchain']; end

    # Fetch a PaymentDTO for a given payment_id using Pi API.
    # Uses all URL/API config from Rails app config (api_key, api_url_base, etc.)
    # @param payment_id [String] The payment identifier
    # @return [PaymentDTO, nil] The payment or nil if not found/error
    def self.get(payment_id)
      key = api_key
      uri = URI.parse("#{api_url_base}/#{api_version}/#{api_controller}/#{payment_id}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      headers = { 'Authorization' => "Key #{key}", 'Content-Type' => 'application/json' }
      req = Net::HTTP::Get.new(uri.path, headers)
      resp = http.request(req)
      return nil unless resp.is_a?(Net::HTTPSuccess)
      begin
        json = JSON.parse(resp.body)
        from_api(json)
      rescue JSON::ParserError
        nil
      end
    rescue StandardError => e
      warn "[PaymentDTO] Error fetching payment: #{e}"
      nil
    end

    # Returns a hash of all properties for serialization.
    def to_h
      {
        identifier: identifier,
        user_uid: user_uid,
        amount: amount,
        description: description,
        metadata: metadata,
        created_at: @_created_at,
        completed_at: completed_at,
        cancelled_at: cancelled_at,
        transaction: transaction,
        username: username,
        error: error,
        status: @status
      }
    end
  end
end
