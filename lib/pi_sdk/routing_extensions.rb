module PiSdk
  module RoutingExtensions
    def pi_sdk(*args, **options)
      args.each do |arg|
        if arg == :payment
          api_controller_name = ::Rails.application.config_for(:pi_sdk)["controller"] || "pi_payment"
          %w{approve cancel complete error incomplete}.each do |verb|
            post "/#{api_controller_name}/#{verb}", to: "pi_sdk/#{api_controller_name}##{verb}"
          end
        end
      end
    end
  end
end
