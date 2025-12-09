# Example Pi network callbacks controller
class PiNetworkCallbacks < PiSdk::PiPaymentController
  # Called on successful approval
  # params: Hash with keys :paymentId, :accessToken; see controller action docs for specifics
  def on_approve_success(params, response)
    # Custom logic for successful approval
  end

  # Called on approval failure
  # params: Hash with keys :paymentId, :accessToken
  def on_approve_failure(params, error)
    # Custom logic for failed approval
  end

  # Called on successful completion
  # params: Hash with keys :paymentId, :transactionId
  def on_complete_success(params, response)
    # Custom logic for successful completion
  end

  # Called on completion failure
  # params: Hash with keys :paymentId, :transactionId
  def on_complete_failure(params, error)
    # Custom logic for failed completion
  end

  # Called on successful cancel
  # params: Hash with key :paymentId
  def on_cancel_success(params, response)
    # Custom logic for successful cancel
  end

  # Called on cancel failure
  # params: Hash with key :paymentId
  def on_cancel_failure(params, error)
    # Custom logic for failed cancel
  end

  # Called on successful error reporting
  # params: Hash with keys :paymentId, :error
  def on_error_success(params, response)
    # Custom logic for successful error reporting
  end

  # Called on error reporting failure
  # params: Hash with keys :paymentId, :error
  def on_error_failure(params, error)
    # Custom logic for failed error reporting
  end

  # Determines how to resolve an incomplete payment event.
  # @param payment_id [String] The Pi payment ID
  # @param transaction_id [String] The transaction ID for the Pi payment
  # @return [Symbol] :complete (to complete payment) or :cancel (to cancel)
  # Returning :complete (default) will finalize the payment; :cancel will cancel it.
  def incomplete_callback(payment_id, transaction_id)
    :complete
  end
end

