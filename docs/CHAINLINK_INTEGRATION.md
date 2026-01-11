# Chainlink Oracle Integration for Rails

## Installation

Add to your Gemfile:
```ruby
gem 'pi-sdk-rails'
```

Run:
```bash
bundle install
rails generate chainlink:install
rails db:migrate
```

## Configuration

Create `config/initializers/chainlink.rb`:
```ruby
Chainlink.configure do |config|
  config.api_key = ENV['CHAINLINK_API_KEY']
  config.network = :testnet
  config.cache_duration = 5.minutes
  config.background_job_queue = :default
end
```

## Usage

### Get Price
```ruby
price = OraclePrice.latest('PI/USD')
puts "PI Price: $#{price.rate}"
```

### Batch Prices
```ruby
prices = OraclePrice.where(pair: ['PI/USD', 'BTC/USD', 'ETH/USD'])
```

### Setup Automation
```ruby
job = KeeperJob.create(
  name: 'Update Prices',
  contract_address: '0x...',
  function_selector: 'updatePrices()',
  status: :active,
  repeat_interval_seconds: 3600
)
```

### Background Jobs
```ruby
UpdateOraclePricesJob.perform_later
ProcessKeeperUpkeepJob.perform_later(job_id)
```

## API Endpoints

- `GET /chainlink/prices` - List all prices
- `GET /chainlink/prices/:pair` - Get specific price
- `POST /chainlink/prices/batch` - Batch request
- `GET /chainlink/health` - System health

## Features

- ✅ ActiveRecord ORM integration
- ✅ Automatic price updates via background jobs
- ✅ Keeper automation tracking
- ✅ ActionCable real-time updates
- ✅ RESTful API endpoints
- ✅ Built-in caching
- ✅ Error handling and monitoring

## Best Practices

1. Always check price freshness before using
2. Implement fallback feeds for critical prices
3. Monitor oracle health regularly
4. Configure proper alert thresholds
5. Test on testnet before production

## Resources

- [Chainlink Documentation](https://docs.chain.link)
- [Triumph Synergy Integration](https://github.com/jdrains110-beep/triumph-synergy)
- [Pi Network Docs](https://developers.minepi.com)
