class ChaincellinkOracleController < ApplicationController
  def prices
    prices = OraclePrice.all.map { |p| { pair: p.pair, rate: p.rate, timestamp: p.timestamp, confidence: p.confidence } }
    render json: prices
  end

  def show
    price = OraclePrice.latest(params[:pair])
    if price
      render json: { pair: price.pair, rate: price.rate, timestamp: price.timestamp, confidence: price.confidence, age: price.age_seconds }
    else
      render json: { error: 'Price not found' }, status: :not_found
    end
  end

  def batch
    pairs = params[:pairs] || []
    prices = OraclePrice.where(pair: pairs).map { |p| { pair: p.pair, rate: p.rate } }
    render json: prices
  end

  def health
    total_prices = OraclePrice.count
    fresh_count = OraclePrice.where('updated_at > ?', 5.minutes.ago).count
    uptime_percentage = (fresh_count.to_f / [total_prices, 1].max * 100).round(2)

    render json: {
      status: uptime_percentage > 80 ? 'healthy' : 'degraded',
      price_feeds: total_prices,
      fresh_feeds: fresh_count,
      uptime: uptime_percentage
    }
  end
end
