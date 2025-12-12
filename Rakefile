require "fileutils"

desc "Sync PiSdkBase.js for codegen/importmap"
task :sync_pi_sdk_base_js do
  src = File.expand_path("node_modules/pi-sdk-js/dist/PiSdkBase.js", __dir__)
  dest = File.expand_path("lib/generators/pi_sdk/install/templates/pi_sdk_base.js", __dir__)
  unless File.exist?(src)
    abort "[Pi SDK] Could not find PiSdkBase.js at #{src}. Run `npm install` in rails_engine first."
  end
  FileUtils.cp(src, dest)
  puts "[Pi SDK] Synced PiSdkBase.js to generator templates."
end
