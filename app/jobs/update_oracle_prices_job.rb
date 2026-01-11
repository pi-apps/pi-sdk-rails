class UpdateOraclePricesJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3

  def perform(*args)
    pairs = ['PI/USD', 'BTC/USD', 'ETH/USD', 'XLM/USD', 'USDC/USD']

    client = Chainlink::Client.new
    prices = client.get_prices(pairs)

    prices.each do |price_data|
      OraclePrice.find_or_create_by(pair: price_data[:pair]).update(
        rate: price_data[:rate],
        timestamp: price_data[:timestamp],
        confidence: price_data[:confidence],
        source: 'chainlink',
        nodes: price_data[:nodes],
        last_update: Time.current
      )
    end

    # Broadcast to ActionCable subscribers
    ActionCable.server.broadcast('oracle_prices', { prices: prices })

    # Schedule next update
    UpdateOraclePricesJob.set(wait: 1.minute).perform_later
  rescue StandardError => e
    Rails.logger.error "Oracle price update failed: #{e.message}"
    Sentry.capture_exception(e) if defined?(Sentry)
  end
end
