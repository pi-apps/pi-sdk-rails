# PiSdk::Rails

This gem allows users to quickly develop Pi Network applications
without getting mired in transaction processing details. The
three-way communication involved to finalize a transaction can be
daunting, but this gem should allow developers to get basic
transaction processing underway with ten minutes of work.

## Development Caveats & Authentication

### Pi authentication
- Should work from localhost. If it does not, notify the Pi Network team.

### **API keys:**
- NEVER commit real API keys to public repositories.
- Reference your API key via an ENV variable in your YAML:

```yaml
# Pi Network Engine Configuration
# NEVER commit real API keys to public repositories!
# Define all Pi API config centrally in _shared and merge into every environment.
_shared: &shared_pi
  # Safe: loads from environment, never commit or hard-code secrets!
  api_key: <%= ENV.fetch("PI_API_KEY") { "" } %>
  api_url_base: "https://api.minepi.com"
  api_version: "v2"
  api_controller: "payments"

development:
  <<: *shared_pi
  hostnames: [your-app.com, localhost]

production:
  <<: *shared_pi
  hostnames: [your-app.com]

test:
  <<: *shared_pi
  hostnames: [your-app.com, localhost]
```
See `config/pi_sdk.yml` for details.

### **X-Frame-Options:**
For Pi Browser/IFrame support, the gem sets `'X-Frame-Options' => 'ALLOWALL'` by default in development via the generated initializer.

---

## Usage

After installation, the developer is responsible for two items:
* Attaching view elements to the Stimulus controller (`pi-sdk` controller, from `pi_sdk_controller.js`)
  * Example: attaching the buy controller action to the "Make Payment" button.
* Providing business logic for server side actions.
  * Example: enable access to product once transaction has been completed.

You can customize all Pi SDK lifecycle logic by subclassing the generated Stimulus controller
(see `app/javascript/controllers/pi_sdk_controller.js` for examples and documentation!)

---

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pi-sdk-rails', path: '/absolute/path/to/pi-sdk-internal/rails_engine'
```
(or replace with your git/registry source)

Run:

```bash
bundle install
```

Once installed, run:

```bash
rails generate pi_sdk:install
```

This will copy initializers/sample Stimulus controllers and JS into your app.

For a quick demonstration that everything works, generate a sample page:

```bash
rails generate controller home index
```

Then add to `app/views/home/index.html.erb`:
```html
<div data-controller="pi-sdk">
  <button type="button" class="btn btn-primary" data-action="click->pi-sdk#buy" disabled data-pi-sdk-target="buyButton">
    Buy
  </button>
</div>
```

Set as root in `config/routes.rb`:
```ruby
root to: "home#index"
```
(Or add the button to your current root page.)

The engine can support transaction recording. It expects two models, a user model and an order model.
The user model will have a new attribute `pi_username` added to it. New users will be created as Pi transactions
come through with novel usernames. The order model should contain information regarding the application's promise
regarding the transaction. As transactions are processed, the status of the associated PiTransaction object will be
updated.

To enable persistent transactions run the following generator:

```bash
rails generate pi_sdk:pi_transaction
```

If your app uses tables other than users/orders, specify them:

```bash
rails generate pi_sdk:pi_transaction user:player order:item
```

Start your server (`bin/dev`) and visit `http://localhost:3000`.

In the browser console you should see:
```
PiSdk controller loaded
Pi SDK initialized in sandbox mode
```

...and then some failures, which will be resolved once you run your app through the Pi Sandbox (see troubleshooting).

---

## Pi Sandbox App Setup

1. Ensure the development server is reachable at `http://localhost:3000`.
   - Use ngrok/Cloudflare if needed for SSL endpoints.
2. In your Pi Network mobile app (Pi Utilities > Develop), register a new app in Test mode.
3. Set "Your App's development URL" to your local server address.
4. Generate your API key, set it in your environment: `export PI_API_KEY=...`
5. Point your browser at `https://sandbox.minepi.com/mobile-app-ui/app/APPNAME`.
6. Follow the Pi Sandbox authorization steps.

---

## Troubleshooting

If Pi authentication hangs ("sending authenticate" but never "finished authenticate"):
- Ensure you are accessing the app over your ngrok HTTPS (not localhost).
- Confirm ngrok URL is in allowed hostnames both on Pi Developer Dashboard and in your config YAML.
- Environment variable for PI_API_KEY is set and available.
- Check for CORS/SSL errors in consoles.
- See docs in your generated initializer and JS controller for extension points.

---

## React/JSBundling Installation

If you use React, Vite, or jsbundling-rails (esbuild, webpack), use the React install generator to skip all importmap and Stimulus-legacy steps:

```bash
rails generate pi_sdk:install_react
```

This copies React entrypoints/components to your app, with instructions included.

---

## Generator Model Constants

The generated PiTransaction model includes these constants for customization:

```ruby
ORDER_KEY_NAME = :order_id
USER_KEY_NAME  = :user_id
ORDER_CLASS    = ::Order
USER_CLASS     = ::User
```

---

## Host App Extensibility

Each payment event triggers two callbacks in `PiPaymentController`:
- An internal private engine hook (`_on_EVENT_success`/`_on_EVENT_failure`)
- An overridable method for the host app (`on_EVENT_success`/`on_EVENT_failure`)

Override these methods for custom server logic as needed.

---

## Contributing

PRs and issues are welcome!

---

## License

The gem is available as open source under the terms of the [PiOS License]. See `LICENSE` for details.

---

## Rake Tasks

After install and migration, the following are available:

- `rake pi_sdk:pi_transactions` — List all PiTransaction records.
- `rake pi_sdk:users` — List user records with pi_username and created_at.

---

**Maintainer:** John Kolen
