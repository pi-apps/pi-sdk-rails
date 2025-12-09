require 'rails/generators/base'

class Pinetwork::InstallReactGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)

  desc 'Adds Pi Network engine configuration for React/JSBundling (esbuild), routes, callback stubs, and Pi SDK integration to your app.'

  def copy_config
    copy_file 'config/pinetwork.yml', 'config/pinetwork.yml'
  end

  def copy_initializer
    template 'config/initializers/pinetwork.rb', 'config/initializers/pinetwork.rb'
  end

  def add_engine_routes
    routes = File.read('config/routes.rb')
    unless routes.include?('mount Pinetwork::Rails::Engine')
      inject_into_file 'config/routes.rb', after: "Rails.application.routes.draw do\n" do
        "  mount Pinetwork::Rails::Engine => \"/pinetwork-rails\"\n"
      end
      say '[Pinetwork] Mounted engine route in config/routes.rb', :green
    else
      say '[Pinetwork] Engine mount already exists in config/routes.rb', :yellow
    end
  end

  def add_pi_payment_routes
    routes = File.read('config/routes.rb')
    routes_block = File.read(File.expand_path('templates/pi_payment_routes.rb', __dir__))
    unless routes.include?('/pi_payment/approve')
      inject_into_file 'config/routes.rb', after: "Rails.application.routes.draw do\n" do
        routes_block
      end
      say '[Pinetwork] Added default Pi payment routes to config/routes.rb', :green
    else
      say '[Pinetwork] Pi payment routes already present in config/routes.rb', :yellow
    end
  end

  # No gem management for JSbundling/React
  def add_gems
    say '[Pinetwork] (JSbundling/React) Skipping Gem dependencies. Please ensure jsbundling-rails, esbuild, and React are installed.', :yellow
  end

  def add_controller_callback_stub
    stub = File.read(File.expand_path('templates/pi_network_callbacks.rb', __dir__))
    create_file 'app/controllers/pi_network_callbacks.rb', stub
  end

  def show_js_todo
    say "\n[TODO] Please add/modify your app/javascript/controllers or components as needed for Pi integration.", :yellow
    say "\nYou now have a pinetwork_controller.js for customization. Import it in your relevant entrypoint.", :yellow
  end

  # No importmap or import injecting for React/esbuild

  def copy_stimulus_controller
    target_path = 'app/javascript/controllers/pinetwork_controller.js'
    unless File.exist?(target_path)
      FileUtils.mkdir_p(File.dirname(target_path))
      copy_file 'pinetwork_controller.js', target_path
      say "Copied pinetwork_controller.js to #{target_path}", :green
    else
      say 'pinetwork_controller.js already exists at #{target_path}', :yellow
    end
  end

  def copy_react_components
    components_dir = 'app/javascript/components'
    FileUtils.mkdir_p(components_dir) unless File.exist?(components_dir)

    react_files = ['PiNetwork.jsx', 'pi_network_base.js', 'PiNetworkComponent.jsx']
    react_files.each do |fname|
      target_path = File.join(components_dir, fname)
      unless File.exist?(target_path)
        copy_file fname, target_path
        say "Copied #{fname} to #{target_path}", :green
      else
        say "#{fname} already exists at #{target_path}", :yellow
      end
    end
  end

  def copy_index_jsx
    components_dir = 'app/javascript/components'
    FileUtils.mkdir_p(components_dir) unless File.exist?(components_dir)
    target_path = File.join(components_dir, 'index.jsx')
    unless File.exist?(target_path)
      copy_file 'index.jsx', target_path
      say "Copied index.jsx to #{target_path}", :green
    else
      say "index.jsx already exists at #{target_path}", :yellow
    end
  end

  def ensure_components_import_in_application_js
    js_file = 'app/javascript/application.js'
    return unless File.exist?(js_file)
    content = File.read(js_file)
    import_line = 'import "./components"'
    unless content.include?(import_line)
      File.open(js_file, 'a') { |f| f.puts(import_line) }
      say("Added 'import \"./components\"' to #{js_file}", :green)
    else
      say("'import \"./components\"' already present in #{js_file}", :yellow)
    end
  end

  def add_pi_sdk_script_tag
    layout_file = 'app/views/layouts/application.html.erb'
    return unless File.exist?(layout_file)
    contents = File.read(layout_file)
    sdk_script = '<script src="https://sdk.minepi.com/pi-sdk.js"></script>'
    if contents.include?(sdk_script)
      say 'Pi SDK <script> tag already present in #{layout_file}', :yellow
      return
    end
    lines = contents.lines
    insert_index = lines.index { |l| l.include?('javascript_importmap_tags') }
    # For React/Vite/etc, still insert after importmaps (if present), otherwise after <head>
    insert_index ||= lines.index { |l| l =~ /<head[^>]*>/ }
    if insert_index
      lines.insert(insert_index + 1, "    #{sdk_script}\n")
      File.write(layout_file, lines.join)
      say 'Inserted Pi SDK <script> tag after importmap_tags or <head> in #{layout_file}', :green
    else
      say 'Could not find reference point in #{layout_file}; Pi SDK script not added.', :red
    end
  end

  def add_rails_env_script_tag
    layout_file = 'app/views/layouts/application.html.erb'
    return unless File.exist?(layout_file)
    contents = File.read(layout_file)
    env_script = '<script>window.RAILS_ENV = "<%= Rails.env %>";</script>'
    if contents.include?(env_script)
      say 'RAILS_ENV <script> tag already present in #{layout_file}', :yellow
      return
    end
    sdk_script = '<script src="https://sdk.minepi.com/pi-sdk.js"></script>'
    lines = contents.lines
    insert_index = lines.index { |l| l.include?(sdk_script) }
    # Otherwise, after <head>
    insert_index ||= lines.index { |l| l =~ /<head[^>]*>/ }
    if insert_index
      lines.insert(insert_index + 1, "    #{env_script}\n")
      File.write(layout_file, lines.join)
      say 'Inserted RAILS_ENV <script> tag after Pi SDK script or <head> in #{layout_file}', :green
    else
      say 'Could not find reference point in #{layout_file}; RAILS_ENV script not added.', :red
    end
  end

  def self.call_all_methods
    gen = new
    gen.copy_config
    gen.copy_initializer
    gen.add_engine_routes
    gen.add_pi_payment_routes
    gen.add_gems
    gen.add_controller_callback_stub
    gen.show_js_todo
    gen.copy_stimulus_controller
    gen.copy_react_components
    gen.copy_index_jsx
    gen.ensure_components_import_in_application_js
    gen.add_pi_sdk_script_tag
    gen.add_rails_env_script_tag
  end
end
