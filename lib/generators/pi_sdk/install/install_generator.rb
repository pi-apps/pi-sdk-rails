require 'rails/generators/base'

class PiSdk::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)

  desc 'Adds Pi SDK engine configuration, routes, gem dependencies, and callback stubs to your app.'

  def copy_config
    copy_file 'config/pi_sdk.yml', 'config/pi_sdk.yml'
  end

  def copy_initializer
    template 'config/initializers/pi-sdk.rb', 'config/initializers/pi-sdk.rb'
  end

  def add_engine_routes
    routes = File.read("config/routes.rb")
    unless routes.include?('mount PiSdk::Engine')
      inject_into_file "config/routes.rb", after: "Rails.application.routes.draw do\n" do
        "  mount PiSdk::Engine => \"/pi-sdk-rails\"\n"
      end
      say "[PiSdk] Mounted engine route in config/routes.rb", :green
    else
      say "[PiSdk] Engine mount already exists in config/routes.rb", :yellow
    end
  end

  def add_pi_payment_routes
    routes = File.read("config/routes.rb")
    routes_block = File.read(File.expand_path('templates/pi_payment_routes.rb', __dir__))
    unless routes.include?('/pi_payment/approve')
      inject_into_file "config/routes.rb", after: "  mount PiSdk::Engine => \"/pi-sdk-rails\"\n" do
        #"Rails.application.routes.draw do\n" do
        routes_block
      end
      say "[PiSdk] Added default Pi payment routes to config/routes.rb", :green
    else
      say "[PiSdk] Pi payment routes already present in config/routes.rb", :yellow
    end
  end

  def add_gems
    gemfile_path = "Gemfile"
    gems = [
      "stimulus-rails",
      "importmap-rails",
      "turbo-rails"
    ]
    gemfile_changed = false
    gems.each do |gemname|
      content = File.read(gemfile_path)
      unless content.include?(gemname)
        append_to_file gemfile_path, "\ngem \"#{gemname}\""
        gemfile_changed = true
        say "Appended #{gemname} to Gemfile", :green
      end
    end
    if gemfile_changed
      say "You should run 'bundle install' to install new dependencies.", :yellow
    end
  end

  def add_controller_callback_stub
    stub = File.read(File.expand_path('templates/pi_sdk_callbacks.rb', __dir__))
    create_file "app/controllers/pi_sdk_callbacks.rb", stub
  end

  def show_js_todo
    say "\n[TODO] Please add the following to your app for JavaScript/STIMULUS integration:", :yellow
    say "\nYou now have a pi_sdk_controller.js, for customization.\n", :yellow
  end

  def inject_controller_import
    js_file = "app/javascript/application.js"
    return unless File.exist?(js_file)
    contents = File.read(js_file)
    import_statement = "import 'pi_sdk/pi_sdk_controller'"
    controllers_import_regex = /^import ['\"]controllers['\"]/
    unless contents.include?(import_statement)
      new_contents = contents.sub(controllers_import_regex) do |match|
        "#{import_statement}\n#{match}"
      end
      File.write(js_file, new_contents)
      say "Inserted 'import 'pi_sdk/pi_sdk_controller'' before 'import 'controllers'' in #{js_file}", :green
    else
      say "'import 'pi_sdk/pi_sdk_controller'' is already present in #{js_file}", :yellow
    end
  end

  def add_importmap_pin
    importmap_file = "config/importmap.rb"
    pin_line = "pin_all_from '../../app/javascript/pi_sdk/controllers', under: 'pi_sdk/controllers'"
    return unless File.exist?(importmap_file)
    contents = File.read(importmap_file)
    unless contents.include?(pin_line)
      lines = contents.lines
      insert_index = lines.rindex { |l| l =~ /^pin/ } || -1
      lines.insert(insert_index + 1, pin_line + "\n")
      File.write(importmap_file, lines.join)
      say "Added pin_all_from for engine Stimulus controllers to config/importmap.rb", :green
    else
      say "pin_all_from for engine controllers already present in config/importmap.rb", :yellow
    end
  end

  def copy_stimulus_controller
    target_path = 'app/javascript/controllers/pi_sdk_controller.js'
    unless File.exist?(target_path)
      FileUtils.mkdir_p(File.dirname(target_path))
      copy_file 'pi_sdk_controller.js', target_path
      say "Copied pi_sdk_controller.js to #{target_path}", :green
    else
      say "pi_sdk_controller.js already exists at #{target_path}", :yellow
    end
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
    insert_index = lines.index { |l| l.include?('javascript_importmap_tags') }
    if insert_index
      # Insert right after the tag
      lines.insert(insert_index + 1, "    #{sdk_script}\n")
      File.write(layout_file, lines.join)
      say "Inserted Pi SDK <script> tag after javascript_importmap_tags in #{layout_file}", :green
    else
      say "Could not find <%= javascript_importmap_tags ... %> in #{layout_file}; Pi SDK script not added.", :red
    end
  end

  def add_rails_env_script_tag
    layout_file = 'app/views/layouts/application.html.erb'
    return unless File.exist?(layout_file)
    contents = File.read(layout_file)
    env_script = '<script>window.RAILS_ENV = "<%= Rails.env %>";</script>'
    if contents.include?(env_script)
      say "RAILS_ENV <script> tag already present in #{layout_file}", :yellow
      return
    end
    sdk_script = '<script src="https://sdk.minepi.com/pi-sdk.js"></script>'
    lines = contents.lines
    insert_index = lines.index { |l| l.include?(sdk_script) }
    if insert_index
      lines.insert(insert_index + 1, "    #{env_script}\n")
      File.write(layout_file, lines.join)
      say "Inserted RAILS_ENV <script> tag after Pi SDK script in #{layout_file}", :green
    else
      say "Could not find Pi SDK <script> tag in #{layout_file}; RAILS_ENV script not added.", :red
    end
  end

  def self.call_all_methods
    new.copy_config
    new.copy_initializer
    new.add_engine_routes
    new.add_pi_payment_routes
    new.add_gems
    new.add_controller_callback_stub
    new.show_js_todo
    new.inject_controller_import
    new.add_importmap_pin
    new.copy_stimulus_controller
    new.add_pi_sdk_script_tag
    new.add_rails_env_script_tag
  end
end
