# Subclass to override Pi payment callbacks
class PiNetworkCallbacks < Pinetwork::Rails::PiPaymentController
  # --- Approval Callbacks ---

  # params: { paymentId:, accessToken: }
  # response: Hash containing the Pi API approval response data
  def on_approve_success(params, response)
    log_callback(:on_approve_success, params: params, result: response)
  end

  # params: { paymentId:, accessToken: }
  # error: Hash or Exception with Pi API error details
  def on_approve_failure(params, error)
    log_callback(:on_approve_failure, params: params, result: error)
  end

  # --- Completion Callbacks ---

  # params: { paymentId:, transactionId: }
  # response: Hash containing the Pi API completion response data
  def on_complete_success(params, response)
    log_callback(:on_complete_success, params: params, result: response)
  end

  # params: { paymentId:, transactionId: }
  # error: Hash or Exception with Pi API error details
  def on_complete_failure(params, error)
    log_callback(:on_complete_failure, params: params, result: error)
  end

  # --- Cancel Callbacks ---

  # params: { paymentId: }
  # response: Hash containing the Pi API cancel response data
  def on_cancel_success(params, response)
    log_callback(:on_cancel_success, params: params, result: response)
  end

  # params: { paymentId: }
  # error: Hash or Exception with Pi API error details
  def on_cancel_failure(params, error)
    log_callback(:on_cancel_failure, params: params, result: error)
  end

  # --- Error Reporting Callbacks ---

  # params: { paymentId:, error: }
  # response: Hash containing the Pi API error reporting response data
  def on_error_success(params, response)
    log_callback(:on_error_success, params: params, result: response)
  end

  # params: { paymentId:, error: }
  # error: Hash or Exception with Pi API error details
  def on_error_failure(params, error)
    log_callback(:on_error_failure, params: params, result: error)
  end

  # --- Incomplete Payment Callback ---

  # @param payment_id [String] The Pi payment ID
  # @param transaction_id [String] The transaction ID for the Pi payment
  # @return [Symbol] :complete (to complete payment) or :cancel (to cancel)
  # Determines what the backend should do for an incomplete payment event.
  # Default is always :complete.
  def incomplete_callback(payment_id, transaction_id)
    :complete
  end

  private
  def log_callback(event, params:, result:)
    Rails.logger.info("[PiNetworkCallbacks] " \
                      "#{event}: params=#{params.inspect}, " \
                      "result=#{result.inspect}")
  end
end
