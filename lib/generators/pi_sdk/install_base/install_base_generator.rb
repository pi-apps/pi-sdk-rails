module PiSdk
  class InstallBaseGenerator < ::Rails::Generators::Base
    source_root File.expand_path("../templates", __FILE__)

    desc "Sets up Pi SDK backend (initializer, config, engine routes, pi_payment routes, controller callbacks)"

    def copy_initializer
      copy_file "config/initializers/pi-sdk.rb", "config/initializers/pi_sdk.rb"
    end

    def copy_config_yml
      copy_file "config/pi_sdk.yml", "config/pi_sdk.yml"
    end

    def add_engine_routes
      route "mount PiSdk::Engine => '/pi-sdk-rails'"
    end

    def add_pi_payment_routes
      route File.read(File.expand_path("pi_payment_routes.rb", self.class.source_root))
    end

    def add_controller_callbacks
      # Optionally copy controller callbacks as needed (if file used)
      callback_dest = "app/controllers/concerns/pi_sdk_callbacks.rb"
      copy_file "pi_sdk_callbacks.rb", callback_dest unless File.exist?(callback_dest)
    end

    def add_pi_sdk_script_tag
      layout_file = 'app/views/layouts/application.html.erb'
      return unless File.exist?(layout_file)
      contents = File.read(layout_file)
      sdk_script = '<script src="https://sdk.minepi.com/pi-sdk.js"></script>'
      if contents.include?(sdk_script)
        say "Pi SDK <script> tag already present in #{layout_file}", :yellow
        return
      end
      lines = contents.lines
      insert_index =
        lines.index { |l| l.include?('javascript_importmap_tags') } ||
        lines.index { |l| l.include?('</head>') }  - 2
      insert_index + 1
      # Insert right after the tag
      lines.insert(insert_index + 1, "    #{sdk_script}\n")
      File.write(layout_file, lines.join)
      say "Inserted Pi SDK <script> tag in #{layout_file}", :green
    end

    def post_install_message
      puts "[Pi SDK] Core backend installed (initializer, config, engine routes, pi_payment routes, callbacks)."
    end
  end
end
