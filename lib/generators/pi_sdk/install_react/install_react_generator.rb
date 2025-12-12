require 'rails/generators/base'

module PiSdk
  class InstallReactGenerator < ::Rails::Generators::Base
    desc "Sets up React frontend for Pi SDK. Installs all backend config, adds npm pi-sdk-react package, and uses plop to scaffold PiButton.jsx."

    def run_backend_setup
      invoke "pi_sdk:install_base"
    end

    def install_react_npm_package
      pkg = "pi-sdk-react"
      if __dir__.include?("pi-sdk-internal")
        pkg = "file:#{File.expand_path("../../../../../react", __dir__)}"
      end
      puts "[Pi SDK React] Installing #{pkg} from npm (this also pulls in pi-sdk-js)..."
      system("yarn add #{pkg}") ||
        system("npm install #{pkg}")
    end

    def run_plop_install
      components_dir = File.expand_path("app/javascript/components",
                                        destination_root)
      FileUtils.mkdir_p(components_dir) unless Dir.exist?(components_dir)
      plopfile = File.expand_path("node_modules/pi-sdk-react/plopfile.js", destination_root)
      puts "[Pi SDK React] Running Plop to scaffold PiButton.jsx with plopfile at #{plopfile}, output: #{components_dir}"
      Dir.chdir(components_dir) do
        cmd = "npx plop pi-sdk:install --plopfile \"#{plopfile}\" --dest ."
        puts cmd
        system(cmd)
      end
    end

    def copy_components_files
      components_dir = File.expand_path("app/javascript/components",
                                        destination_root)
      # Copy index.jsx
      template_path = File.expand_path("../templates/index.jsx", __FILE__)
      dest_path = File.join(components_dir, "index.jsx")
      FileUtils.cp(template_path, dest_path)
      puts "[Pi SDK React] Copied index.jsx to #{dest_path}"
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

    def post_install_message
      puts "[Pi SDK React] React frontend support installed. " \
           "Add <PiButton /> to your UI as needed."
    end
  end
end
