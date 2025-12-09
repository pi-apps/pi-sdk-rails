class Pinetwork::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)
end

require 'rails/generators/base'

module Pinetwork
#  module Generators
    class xInstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Adds Pi Network engine configuration and routes to your app.'

      def copy_config
        template 'config/pinetwork.yml', 'config/pinetwork.yml'
      end

      def add_engine_routes
        routes = File.read("config/routes.rb")
        unless routes.include?('mount Pinetwork::Rails::Engine')
          inject_into_file "config/routes.rb", after: "Rails.application.routes.draw do\n" do
            "  mount Pinetwork::Rails::Engine => \"/pinetwork-rails\"\n"
          end
          say "[Pinetwork] Mounted engine route in config/routes.rb", :green
        else
          say "[Pinetwork] Engine mount already exists in config/routes.rb", :yellow
        end
      end

      def add_pi_payment_routes
        pi_routes_block = <<-RUBY
  # BEGIN PiNetwork::Rails default payment routes
  post '/pi_payment/approve',   to: 'pinetwork/rails/pi_payment#approve'
  post '/pi_payment/complete',  to: 'pinetwork/rails/pi_payment#complete'
  post '/pi_payment/cancel',    to: 'pinetwork/rails/pi_payment#cancel'
  post '/pi_payment/error',     to: 'pinetwork/rails/pi_payment#error'
  get  '/pi_payment/me',        to: 'pinetwork/rails/pi_payment#me'
  # END PiNetwork::Rails default payment routes

RUBY
        routes = File.read("config/routes.rb")
        unless routes.include?('pinetwork/rails/pi_payment')
          inject_into_file "config/routes.rb", after: "Rails.application.routes.draw do\n" do
            pi_routes_block
          end
          say "[Pinetwork] Added default Pi payment routes to config/routes.rb", :green
        else
          say "[Pinetwork] Pi payment routes already present in config/routes.rb", :yellow
        end
      end

      def show_readme
        say "\n[Pinetwork] Installed config/pinetwork.yml. Edit it to set your Pi Network API key(s).\n", :green
        say "[Pinetwork] Make sure your app's config/routes.rb includes the engine mount and default pi_payment endpoints (added automatically unless present).\n", :green
      end
    end

end
