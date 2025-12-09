# Pinetwork::Rails
This gem allows users to quickly develop Pi network applications
without getting mired in transaction processing details. The
three-way communication involved to finalize a transaction can be
daunting, but this gem should allow developers to get basic
transaction processing underway with ten minutes of work.

## Development Caveats & Authentication

Pi authentication should work from localhost. If it does not, let the Pi Network team know.

**API keys:**
- NEVER commit real API keys to public repositories.
- Reference your API key via an ENV variable in your YAML:

```yaml
# Pi Network Engine Configuration
#
# NEVER commit real API keys to public repositories!
# Define all Pi API config centrally in _shared and merge into every environment.
# You can override api_key, api_url_base, api_version, or api_controller in any environment if needed.
_shared: &shared_pi
  # Safe: loads from environment, never commit or hard-code secrets!
  api_key: <%= ENV.fetch("PI_API_KEY") { "" } %>
  api_url_base: "https://api.minepi.com"
  api_version: "v2"
  api_controller: "payments"

# Your ngrok or app hostnames for each environment should be listed here.
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
See `config/pinetwork.yml` for details.

**X-Frame-Options:**
Fo Pi Browser/IFrame support, the gem sets `'X-Frame-Options' => 'ALLOWALL'` by default in
development via the generated initializer.

## Usage
After installation, the developer is responsible for two items:
* Attaching view elements to the Stimulus controller (`pinetwork`-controller).
  * Example: attaching the buy controller action to the "Make Payment" button.
* Providing business logic for server side actions.
  * Example: enable access to product once transaction has been completed

You can customize all Pi SDK lifecycle logic by subclassing the generated Stimulus controller
(see `app/javascript/controllers/pinetwork_controller.js` for examples and documentation!)

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'pinetwork-rails', git: 'https://github.com/pi-apps/pi-network-rails.git'
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install pinetwork-rails # not available now
```

Once the gem has installed:
```bash
$ rails generate pinetwork:install
```

For a quick demonstration that everything works, you can:
```bash
$ rails generate controller home index
```
This will create a demo page. Then add the following to app/views/home/index.html.erb:
```html
<div data-controller="pinetwork">
  <button type="button" class="btn btn-primary" data-action="click->pinetwork#buy" disabled data-pinetwork-target="buyButton">
    Buy
  </button>
</div>
```
Then make this page root by adding the following line to your config/routes.rb file:
```ruby
root to: "home#index"
```

If you already have a root page, add the button to it. Otherwise, follow the directions above.

The engine can support transaction recording. It expects two models, a user model and an order model.
The user model will have a new attribute `pi_username` added to it. New users will be created as Pi transations
come through with novel usernames. The order model should contain information regarding the application's promise
regarding the transaction. As transaction are processed, the status of the associated PiTransation object will be
updated. To enable persistent transactions run the following generator.
```bash
rails generate pinetwork:pi_transaction
```
If your applicaiton uses tables other than users and orders, the add the correct tables to the generator.
```bash
rails generate pinetwork:pi_transaction user:player order:item
```

Start the development server (`bin/dev`) and visit root (`http://localhost:3000`).
You should see logs (in your browser JS console):
```
PiNetwork controller loaded
Pi SDK initialized in sandbox mode
```
...and then some failures. These will be resolved by running your app through the
Pi Sandbox. This will take a few steps. These steps presume you are running the
development server locally.

### Pi Sandbox App
1. Make sure you can access the server through `http://localhost:3000`.
1. Open your Pi Network mobile app and visit Pi Utilities > Develop. Click 'New App'.
   - Enter your App Name and Description. Set App Network to Pi Test. Submit.
   - Click Configuration, insert `http://localhost:3000` into "Your App's development URL". Submit.
   - You can leave "Your App's URL" blank for now.
   - Click API Key and generate one.
   - Copy (and secure) your API key; set `PI_API_KEY` in your environment.
1. Aim your browser at `https://sandbox.minepi.com/mobile-app-ui/app/APPNAME`.
1. Follow the directions for Sandbox access. ("Authorize Sandbox" is at the bottom of the Pi Utilities page.)

## Troubleshooting
If Pi authentication hangs (logs "sending authenticate" but never "finished authenticate"):
- Make sure you are accessing your app over your ngrok HTTPS URL, not localhost.
- Verify your ngrok URL is listed as an allowed hostname in both your Pi Developer Dashboard and in your YAML config.
- Check that your API key is set via ENV and available to Rails.
- Inspect your browser and server consoles for CORS or SSL errors.
- Read generated documentation in `config/pinetwork.yml`, the initializer, and in the generated JavaScript controller for extension points and safe config.

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [PiOS License]. See `LICENSE` for details.

## Rake Tasks

After installation and migration, the following rake tasks are available:

- `rake pinetwork:pi_transactions`
  Lists all PiTransaction records, showing `id`, `payment_id`, `state`, `user_id`, and `created_at`.

- `rake pinetwork:users`
  Lists all user records from the model referenced by `PiTransaction::USER_CLASS`, displaying `id`, `pi_username`, and `created_at`.

## Generator Model Constants

The generated PiTransaction model includes the following constants to make associated lookups flexible and robust:

```ruby
ORDER_KEY_NAME = :order_id     # or your custom order association foreign key
USER_KEY_NAME  = :user_id      # or your custom user association foreign key
ORDER_CLASS    = ::Order       # the associated order class object
USER_CLASS     = ::User        # the associated user class object
```
You can use these in your own integration code for dynamic/reflective queries and relationships.

## User Model Requirements and Unique Index

The PiTransaction generator will automatically:
- Add a `pi_username` (string) column to your user table (if not already present)
- Add a unique index on the `pi_username` column

This guarantees that Pi users match uniquely to your application users and prevents duplicate records for the same username.

## Host App Extensibility via Overridable Callbacks

Each payment lifecycle event triggers two callbacks in `PiPaymentController`:

- An internal private engine hook for processing (`_on_EVENT_success`/`_on_EVENT_failure`)
- A public overridable method designed for host app extension (`on_EVENT_success`/`on_EVENT_failure`)

This allows you to define custom logic either by subclassing or directly implementing these `on_*` methods in your host app controller.

## React/JSBundling Installation

**If you are using React, Vite, or jsbundling-rails (esbuild, webpack), use the React install generator to skip all importmap and Stimulus-legacy steps:**

```bash
rails generate pinetwork:install_react
```

This will:

- Copy engine configuration, routes, and initializer as normal.
- Place `PiNetwork.jsx`, `PiNetworkComponent.jsx`, and `pi_network_base.js` in your app’s `app/javascript/components` directory.
- Place a React entrypoint `index.jsx` in `app/javascript/components`.
- Ensure your `app/javascript/application.js` includes `import "./components"` so your React code is bundled.
- Insert required `<script>` tags (API SDK and `window.RAILS_ENV`) into `app/views/layouts/application.html.erb` for you.

**To mount the component:**

1. In one of your Rails views, add:

    ```erb
    <div id="pinetwork"></div>
    ```

2. The `index.jsx` will automatically find this div and mount the PiNetwork React component on page load.

You may edit or extend `PiNetwork.jsx` or `PiNetworkComponent.jsx` to suit your app's UI or payment flow.

**Do not use the original `pinetwork:install` generator if you are using React/jsbundling-rails!**  
The React generator avoids all importmap-related dependencies and assumes you're using modern JS build tooling.
