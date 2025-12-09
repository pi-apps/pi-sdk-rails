# pi-sdk-rails

A Rails engine for rapid integration of the Pi Network API for transactions and payments.

## Overview

**pi-sdk-rails** provides routes, controllers, and generators for adding Pi Network payment and authentication flows to your Rails application. It is namespaced under `PiSdk` and provides out-of-the-box controllers and helpers, as well as a generator to scaffold Stimulus controllers or initial JS code.

## Installation

Add the engine to your Gemfile (if developing locally, update the path accordingly):

```ruby
gem 'pi-sdk-rails', path: '/absolute/path/to/pi-sdk-internal/rails_engine'
```

And run:

```sh
bundle install
```

## Usage

### Mount the Engine

In your application's `config/routes.rb`:

```ruby
mount PiSdk::Engine => "/pi-sdk-rails"
```

This makes the engine's routes available under `/pi-sdk-rails/*` paths.

---

### Use the Install Generator

To add Stimulus controllers or setup JS in your host app, run:

```sh
rails generate pi_sdk:install
```

- This copies template files, such as `pi_sdk_controller.js`, into your `app/javascript/controllers/` (for use with Stimulus or importmap/esbuild setups).
- Use `<div data-controller="pi-sdk">` (or appropriate for your JS stack) to enable the Stimulus controller.
- For custom controller naming: see [Stimulus docs](https://stimulus.hotwired.dev/reference/controllers#identifiers).

---
### Example Engine Controller Route

```ruby
# in config/routes.rb (of app _or_ engine test/dummy)
post '/pi_payment/approve', to: 'pi_sdk/pi_payment#approve'
```

---
### Example Engine Controller Declaration

```ruby
# app/controllers/pi_sdk/pi_payment_controller.rb
module PiSdk
  class PiPaymentController < ApplicationController
    def approve
      # ...
    end
  end
end
```

---

## Contributing

1. Fork and clone the repo
2. Make changes on a branch
3. Open PR with details

## Development
- Run tests with `bundle exec rspec` or your preferred test runner.
- Dummy app for integration testing is under `spec/dummy/`.

---
**Author:** John Kolen
