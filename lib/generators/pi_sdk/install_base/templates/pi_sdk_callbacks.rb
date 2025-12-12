# app/controllers/concerns/pi_sdk_callbacks.rb
#
# Example overridable callbacks for PiSdk payment lifecycle
module PiSdkCallbacks
  extend ActiveSupport::Concern

  # Override in your controllers as needed
  def on_approve_success(payment, user)
    # ...
  end

  def on_approve_failure(payment, user)
    # ...
  end

  # Add more callbacks for cancel, complete, error, incomplete as needed
end


