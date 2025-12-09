require 'net/http'
require 'uri'
require 'json'
require_relative '../../../models/pinetwork/rails/user_d_t_o'
require_relative '../../../models/pinetwork/rails/payment_d_t_o'

module Pinetwork
  module Rails
    module ApiConfig
      def api_config
        ::Rails.application.config_for(:pinetwork)
      end
      def api_url_base;   api_config['api_url_base'];   end
      def api_version;    api_config['api_version'];    end
      def api_controller; api_config['api_controller']; end
      def api_key;        api_config['api_key'];        end
    end

    class PiPaymentController < ApplicationController
      include ApiConfig
      # NOTE: All critical Pi API config is now read dynamically from config/pinetwork.yml using the ApiConfig module.
      # You can override api_url_base, api_version, api_controller, and api_key in your config files.

      before_action :ensure_json_request
      skip_before_action :verify_authenticity_token

      rescue_from JSON::ParserError do |e|
        logger.error("Unparseable JSON payload: #{e.message}")
        render json: { error: "Unparseable JSON payload: #{e.message}" },
               status: :unprocessable_entity
      end

      # POST /piu_payment/approve
      # Params:
      #   - accessToken [String] (required): The Pi user access token.
      #   - paymentId   [String] (required): The Pi payment ID.
      def approve
        return unless (access_token, payment_id =
                       get_required_params(:accessToken, :paymentId)).first
        user_dto = ::Pinetwork::Rails::UserDTO.get(access_token)
        unless user_dto
          logger.error("Invalid or unauthorized Pi access token (failed UserDTO.get) for payment approved request")
          return render json: { error: 'Invalid or unauthorized Pi access token' },
                        status: :unauthorized
        end
        user = find_or_create_pi_user_by_username(user_dto.username)
        @pi_transaction = find_or_create_pi_transaction_for_approval(payment_id, user)
        pi_post_to_server(
          'approve',
          payment_id,
          { paymentId: payment_id, accessToken: access_token },
          log_ok:   "Pi payment approved for paymentId=#{payment_id}",
          log_fail: "Pi approve error for paymentId=#{payment_id}"
        )
      end

      # POST /pi_payment/complete
      # Params:
      #   - paymentId       [String] (required): The Pi payment ID.
      #   - transactionId   [String] (required): The Pi transaction ID.
      def complete
        return unless (payment_id, transaction_id =
                       get_required_params(:paymentId, :transactionId)).first
        payment = ::Pinetwork::Rails::PaymentDTO.get(payment_id)
        unless payment
          logger.error("Invalid or unauthorized Pi payment_id for payment complete request")
          return render json: { error: 'Invalid or unauthorized Pi payment_id' },
                        status: :unauthorized
        end
        if Object.const_defined?("PiTransaction")
          @pi_transaction = ::PiTransaction.find_by_pi_payment_id(payment_id)
          if @pi_transaction
            @pi_transaction.update!(txid: transaction_id,
                                    state: :completion_pending)
          else
            logger.error("Asked to complete an unknown transaction #{payment_id}")
            return render json: { error: 'Unauthorized Pi payment_id' },
                          status: :unauthorized
          end
        end
        pi_post_to_server(
          'complete',
          payment_id,
          { paymentId: payment_id, txid: transaction_id },
          log_ok:   "Pi payment completed for paymentId=#{payment_id}, transactionId=#{transaction_id}",
          log_fail: "Pi complete error for paymentId=#{payment_id}, transactionId=#{transaction_id}"
        )
      end

      # POST /pi_payment/cancel
      # Params:
      #   - paymentId [String] (required): The Pi payment ID.
      def cancel
        return unless (payment_id, = get_required_params(:paymentId)).first
        if Object.const_defined?("PiTransaction")
          @pi_transaction = ::PiTransaction.find_by_pi_payment_id(payment_id)
          if @pi_transaction
            @pi_transaction.update!(state: :cancel_pending)
          else
            logger.error("Asked to cancel an unknown transaction #{payment_id}")
            return render json: { error: 'Unauthorized Pi payment_id' },
                          status: :unauthorized
          end
        end
        pi_post_to_server(
          'cancel',
          payment_id,
          { paymentId: payment_id },
          log_ok:   "Pi payment cancelled for paymentId=#{payment_id}",
          log_fail: "Pi cancel error for paymentId=#{payment_id}"
        )
      end

      # POST /pi_payment/error
      # Params:
      #   - paymentId [String] (required): The Pi payment ID.
      #   - error     [Any]    (required): Error detail object or message.
      def error
        return unless (payment_id, error_data =
                       get_required_params(:paymentId, :error)).first
        unless payment_id && error_data
          logger.error("Missing payment_id or error data in error request")
          return render json: {
                          error: 'Missing payment_id or error data'
                        },
                        status: :bad_request
        end
        if Object.const_defined?("PiTransaction")
          @pi_transaction = ::PiTransaction.find_by_pi_payment_id(payment_id)
          if @pi_transaction
            @pi_transaction.update!(state: :error)
          else
            logger.error("Error reported for an unknown payment #{payment_id}: #{error_data.inspect}")
            return render json: { error: 'Unauthorized Pi payment_id' },
                          status: :unauthorized
            _on_error_failure()
          end
        end
        logger.info("Error reported for payment #{payment_id}: #{error_data.inspect}")
        render json: {recorded: true},
               status: :ok
        _on_error_success(payment_id, error_data)

        # pi_post_to_server(
        #   'error',
        #   payment_id,
        #   { paymentId: payment_id, error: error_data },
        #   log_ok:   "Pi payment error report for payment_id=#{payment_id}",
        #   log_fail: "Pi error report for payment_id=#{payment_id}"
        # )
      end

      # POST /pi_payment/incomplete
      # Params:
      #   - paymentId      [String] (required): The Pi payment ID.
      #   - transactionId  [String] (required): The transaction ID from Pi network.
      # Handles incomplete payments. The default incomplete_callback returns :complete.
      # Host apps can override incomplete_callback to implement custom review logic.
      # If the callback returns :complete, the server completes the payment;
      # if :cancel, cancels it.
      def incomplete
        return unless (payment_id, transaction_id =
                       get_required_params(:paymentId, :transactionId)).first
        decision = incomplete_callback(payment_id, transaction_id)
        case decision
        when :complete
          pi_post_to_server(
            'complete',
            payment_id,
            { paymentId: payment_id, txid: transaction_id },
            log_ok:   "Pi payment completed for incomplete " \
                      "payment_id=#{payment_id} transaction_id=#{transaction_id}",
            log_fail: "Pi completion from incomplete failed for payment_id=#{payment_id}"
          )
        when :cancel
          pi_post_to_server(
            'cancel',
            payment_id,
            log_ok:   "Pi payment cancelled for incomplete payment_id=#{payment_id}",
            log_fail: "Pi cancel from incomplete failed for payment_id=#{payment_id}"
          )
        else
          logger.error("incomplete_callback must return :complete or " \
                       ":cancel, got #{decision.inspect}")
          render json: { error: "incomplete_callback must return :complete or :cancel" },
                 status: :bad_request
        end
      end

      # GET /pi_payment/me
      # This endpoint is not implemented server-side. Will raise error if called.
      def me
        logger.error(
          "'me' endpoint is not implemented or not necessary on the server. " \
          "If called, please remove or revise logic."
        )
        raise NotImplementedError,
              "'me' endpoint should not be called from server."
      end

      private

      def parse_json_body
        return if request.body.nil? || request.body.size.zero?
        body = request.body.read
        JSON.parse(body).with_indifferent_access
      rescue JSON::ParserError
        # The rescue_from block will handle this error globally.
        raise
      end

      # Helper to extract a list of required params from parsed JSON body or params.
      # If any param is missing, logs and renders an error, returns all nils.
      # Side-effect: This method will render a response and halt the action on error.
      def get_required_params(*param_names)
        parsed_params = parse_json_body || params
        result = param_names.map { |name| parsed_params[name] }
        if result.any?(&:nil?)
          missing = param_names.zip(result).select { |_, v| v.nil? }.map(&:first)
          logger.error("Missing required params: #{missing.join(', ')}")
          render json: {
                   error: "Missing required params: #{missing.join(', ')}"
                 },
                 status: :bad_request
          return [nil] * param_names.size
        end
        result
      end

      def pi_url(payment_id, action)
        URI.parse("#{api_url_base}/#{api_version}/#{api_controller}/#{payment_id}/#{action}")
      end

      # Returns the Pi API key from config at runtime
      def pi_api_key
        api_key.tap { |k| raise "No PI API key" if k.blank? }
      end

      def pi_headers
        {
          'Content-Type' => 'application/json',
          'Authorization' => "Key #{pi_api_key}"
        }
      end

      def ensure_json_request
        return if request.format.json?
        head :not_acceptable
      end

      # Makes a POST request to the Pi Network server for a given action.
      #
      # @param action     [String]   The Pi API action (approve, complete, error, etc.)
      # @param payment_id [String]   The payment ID this request concerns.
      # @param body       [Hash, nil]  The JSON payload to send (optional).
      # @param opts       [Hash]
      #   - :log_ok   [String]  Log message for successful request (optional)
      #   - :log_fail [String]  Log message for failed request (optional)
      #   - :header   [Hash]    Additional headers to merge into request (optional)
      #
      # On success: logs, sends callback "on_#{action}_success", renders JSON response.
      # On error:   logs, sends callback "on_#{action}_failure", renders error JSON.
      def pi_post_to_server(
            action,
            payment_id,
            body = nil,
            opts = {}
          )
        url = pi_url(payment_id, action)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = (url.scheme == 'https')
        headers = pi_headers
        headers.merge!(opts[:header]) if opts[:header]
        req = Net::HTTP::Post.new(url.path, headers)
        ruby_body = body.presence || {}
        req.body = ruby_body.to_json
        response = http.request(req)
        begin
          res_json = JSON.parse(response.body)
          logger.info(
            (opts[:log_ok] || "Pi server POST #{action} succeeded") +
            ", response: #{res_json.inspect}"
          )
          send_callback("_on_#{action}_success", params, res_json)
          render json: res_json, status: :ok
          true
        rescue JSON::ParserError
          logger.error(
            (opts[:log_fail] || "Pi server POST #{action} failed") +
            ": Invalid JSON. Status: #{response.code}, Body: #{response.body}"
          )
          send_callback("_on_#{action}_failure", params, response.body)
          render json: {
                   error: 'Invalid response from Pi API',
                   status: response.code,
                   body: response.body
                 },
                 status: :bad_gateway
          nil
        end
      end

      def send_callback(cb_name, params, obj)
        if respond_to?(cb_name, true)
          send(cb_name, params, obj)
        end
      end

      # User/host app can override these via subclass with custom logic
      def on_approve_success(params, response); end
      def on_approve_failure(params, error); end
      def on_complete_success(params, response); end
      def on_complete_failure(params, error); end
      def on_cancel_success(params, response); end
      def on_cancel_failure(params, error); end
      def on_error_success(params, response); end
      def on_error_failure(params, error); end

      protected
      # Override this for custom incomplete payment logic.
      # @param payment_id [String]
      # @param transaction_id [String]
      # @return [Symbol] either :complete (default) or :cancel
      # Returning :complete will instruct the server to complete the payment.
      # Returning :cancel will instruct the server to cancel the incomplete payment.
      def incomplete_callback(payment_id, transaction_id)
        :complete
      end

      private

      def find_or_create_pi_user_by_username(username)
        return nil unless Object.const_defined?("PiTransaction")
        user_class = ::PiTransaction::USER_CLASS
        user = user_class.find_by(pi_username: username)
        return user if user.present?
        begin
          puts "attempting create! pi_username: #{username}"
          u = user_class.create!(pi_username: username)
          puts u.inspect
          u
        rescue ActiveRecord::RecordNotUnique
          puts "attempting find_by pi_username: #{username}"
          user_class.find_by(pi_username: username)
        end
      end

      def find_or_create_pi_transaction_for_approval(payment_id, user)
        puts "user = #{user.inspect}"
        return nil unless Object.const_defined?("PiTransaction")
        puts "::PiTransaction::USER_KEY_NAME = #{::PiTransaction::USER_KEY_NAME.inspect}"
        ::PiTransaction.find_or_create_by_pi_payment_id(
          payment_id,
          state: :approval_pending,
          ::PiTransaction::USER_KEY_NAME => user&.id
        )
      end

      # Private engine processing hooks
      private

      def _on_approve_success(params, response);
        @pi_transaction.update!(state: :approved) if @pi_transaction
      end
      def _on_approve_failure(params, error);
        @pi_transaction.update!(state: :approval_failed) if @pi_transaction
      end
      def _on_complete_success(params, response);
        @pi_transaction.update!(state: :completed) if @pi_transaction
      end
      def _on_complete_failure(params, error);
        @pi_transaction.update!(state: :complete_failed) if @pi_transaction
      end
      def _on_cancel_success(params, response);
        @pi_transaction.update!(state: :cancelled) if @pi_transaction
      end
      def _on_cancel_failure(params, error);
        @pi_transaction.update!(state: :cancel_failed) if @pi_transaction
      end
      def _on_error_success(params, response); end
      def _on_error_failure(params, error); end

    end
  end
end
