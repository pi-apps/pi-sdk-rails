#
# WARNING: Do not use module nesting like PiSdk::Generators or PiSdk::Rails here.
# Rails looks for PiSdk::InstallGenerator directly, and only this will be found by "rails generate pi_sdk:install".
# Also, always use ::Rails::Generators::Base to ensure correct ancestor, not a potentially shadowed module.
#

module PiSdk
  class InstallGenerator < ::Rails::Generators::Base
    source_root File.expand_path("../templates", __FILE__)

    desc "Sets up Stimulus frontend with Pi SDK buy button and invokes all core backend setup (see pi_sdk:install_base)"

    def run_backend_setup
      invoke "pi_sdk:install_base"
    end

    def copy_stimulus_controller
      copy_file "pi_sdk_controller.js", "app/javascript/controllers/pi_sdk_controller.js"
    end

    def pin_pi_sdk_base_for_importmap
      importmap_path = "config/importmap.rb"
      pin_line = 'pin "pi_sdk", to: "pi-sdk-rails/pi_sdk"'
      if File.exist?(importmap_path) && File.foreach(importmap_path).none? { |line| line.include?(pin_line) }
        append_to_file importmap_path, "\n#{pin_line}\n"
      end
    end

    def post_install_message
      puts "\n[Pi SDK] Stimulus controller and backend/core setup installed. Importmap pin added."
      puts "Restart the Rails server or bin/dev if needed."
    end
  end
end
