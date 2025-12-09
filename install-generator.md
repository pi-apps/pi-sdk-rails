The engine needs an installation generator called pinetwork:install

It can be created with "rails generate generator pinetwork/install"

For the tasks below it will be generalizing content from the dummy app.

Do NOT insert a Generator module in install_generator.rb. Adding the module prevents the main app from finding the generator.

**When adding Ruby code to generator templates via heredoc, always use single-quoted heredocs (<<-'RB') if your template should contain #{...} interpolation that must be literal in the output file. Using double-quoted heredocs (<<-RB) can cause Ruby to evaluate #{...} at generator run time, leading to NameError.**

> When displaying Ruby code blocks containing a variable (such as #{e}), always use a single-quoted heredoc (<<-'EOM') so the interpolation is treated as literal and not evaluated at generator runtime. Never use double-quoted heredocs for generator output that needs to include interpolation in the generated/app file itself.

It should performe the following tasks
- Add a config/pinetwork.yml file. It should allow definitions of api_key and hostnames for each environment.
- Add the engine routes.rb
--   mount Pinetwork::Rails::Engine => "/pinetwork-rails"
- Copy the pi_payment routes from the dummy app routes.rb
- Ensure host app’s JS packs/importmap pins to your engine’s Stimulus controllers.
- Register engine-provided controllers in the host app’s JS entrypoint
- Add the custome callbacks controller PinetworkCallbacks that subclasses Pinetwork::Rails::PiPaymentController
- Add stiumulus-rails, importmap-rails, and turbo-rails to the Gemfile and bundle install
- Add import "pinetwork/pinetwork_controller" before import "controllers" in app/javascript/application.js
- Add stimulus controller pinetwork_controller.js to the app
- Copy config/initializes/pinetwork.rb into the app
