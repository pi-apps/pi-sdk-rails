# Pi SDK Rails Engine – External Developer Guide

This gem lets you quickly integrate the Pi Network payment/identity SDK into your Rails application. It automates nearly all the configuration and backend logic for a secure, full-stack Pi Network payments workflow, lifecycle callbacks, and user/transaction associations for your app.

---

## 🚀 Quick Start

1. **Add to your Gemfile:**
   ```ruby
   gem 'pi-sdk-rails', git: 'https://github.com/pi-apps/pi-sdk-rails.git'
   ```
2. **Install and generate engine files:**
   ```sh
   bundle install
   rails generate pi_sdk:install
   ```
3. **Set up your Pi API keys/config:**
   - Copy your API key into an ENV variable (e.g. `PI_API_KEY`).
   - Configure `config/pi_sdk.yml` for your Pi developer/test/production URLs and settings.
   - Add `<script src="https://sdk.minepi.com/pi-sdk.js"></script>` to your main app layout (if not added automatically).
4. **Set up routes and buttons:**
   - Example view usage:
     ```erb
     <div data-controller="pinetwork">
       <button type="button" class="btn" data-action="click->pinetwork#buy" data-pinetwork-target="buyButton" disabled>
         Buy
       </button>
     </div>
     ```
5. **Start your server:**
   ```sh
   bin/dev
   # or rails s
   ```

---

## 📦 What This Provides
- **Stimulus controller/API endpoints/user+transaction models** prebuilt
- **Pi payment lifecycle:** approve, complete, cancel, error, and incomplete callbacks handled server-side
- **Automatic user association:** `pi_username` and order references
- **Your database is kept in sync with all Pi payment events**
- **All Pi SDK config in YAML and environment variables; never commit secrets**
- **React/jsbundling integration generator:** For modern JS apps, use `rails generate pi_sdk:install_react` instead — this skips importmaps and adds a ready-to-go Pi React button/component.

---

## 🔑 Key Details
- **Dev/test/production ready.**
- **Add Pi SDK `<script>` tag to your HTML:**
  ```erb
  <script src="https://sdk.minepi.com/pi-sdk.js"></script>
  ```
- **Customize all payment/server logic:** Override controller methods for transaction lifecycle as needed (see generated controller and [docs](https://developer.minepi.com/)).
- **Config:** API keys and sensitive settings are never checked into git. Use `config/pi_sdk.yml` and ENV variables.
- **Rails 6, 7, and 8 compatible.**

---

## 📹 Video Script
Here's are the commands used in the video for the Stimulus version.
```bash
# Create the app
rails new tmtt

cd tmtt

# Add the gem to the app
echo "gem 'pi-sdk-rails', git: 'https://github.com/pi-apps/pi-sdk-rails.git'" >> Gemfile
bundle install

# Generate the necessary local files
rails generate pi_sdk:install

# Set up an example button
# Create a view and controller
rails generate controller root index

# Make the root#index root for tha app
sed -i '' -e "s/# root \".*\"/root to: 'root#index'/" config/routes.rb

# Add a Buy button to the end of the root#index page
cat - >> app/views/root/index.html.erb <<HTML
<div data-controller="pi-sdk">
<button type="button" class="btn btn-primary" data-action="click->pi-sdk#buy" disabled data-pi-sdk-target="buyButton">
Buy
</button>
</div>
HTML

# Make PI_API_KEY available
source ../secrets

# Run the app
bin/dev

# Add PiTransaction model to the app

rails generate model User email
rails generate model Order description:string
rails generate pi_sdk:pi_transaction

rake db:migrate

# Run the app
bin/dev
```

Here's are the commands used in the video for the React version.
```bash
# Create the app
rails new tmtt

cd tmtt

# Add the gem to the app
echo "gem 'pi-sdk-rails', git: 'https://github.com/pi-apps/pi-sdk-rails.git'" >> Gemfile
bundle install

# Generate the necessary local files
rails generate pi_sdk:install_react

# Set up an example button
# Create a view and controller
rails generate controller root index

# Make the root#index root for tha app
sed -i '' -e "s/# root \".*\"/root to: 'root#index'/" config/routes.rb

# Add a Buy button to the end of the root#index page
cat - >> app/views/root/index.html.erb <<HTML
<div id="pi-sdk" />
HTML

# Make PI_API_KEY available
source ../secrets

# Run the app
bin/dev

# Add PiTransaction model to the app

rails generate model User email
rails generate model Order description:string
rails generate pi_sdk:pi_transaction

rake db:migrate

# Run the app
bin/dev
```

---
## ❓ FAQ

### How do I connect the frontend button to payment logic?
Use provided Stimulus or React components. Target a `<button>` and add the appropriate Stimulus `data-controller` and data-action attributes, or use/modify the generated `PiButton.jsx` if using React.

### How do I record/reference users and orders?
- The engine ties all transactions to a unique user (by pi_username) and an order/payment model you control.
- Use provided generators to add migrations/models for unique Pi users and transactions.

### Does this handle CORS, sandbox, and IFrame caveats?
- Yes—sane defaults and config are provided for Pi browser requirements.

### How do I test locally with the Pi Sandbox?
- Set your Pi app’s dev/test URL to your local server (with ngrok for mobile testing).
- Follow Pi’s developer portal setup and set ENV API key.
- Sandbox/test network flows are handled out of the box.

### Is there a React/Vite/jsbundling workflow?
Absolutely! Use:
```sh
rails generate pi_sdk:install_react
```
This generator sets up React/Vite entrypoints, JSX components, and avoids importmap dependencies.

---

## 📚 Further Resources
- [Official Pi SDK Docs](https://developer.minepi.com/)
- [Gem README & guides](https://github.com/pi-apps/pi-sdk-rails)
- Your generated `app/controllers/pi_sdk/pi_payment_controller.rb` for server-side extension.
