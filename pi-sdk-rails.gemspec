require_relative "lib/pi_sdk/version"

Gem::Specification.new do |spec|
  spec.name        = "pi-sdk-rails"
  spec.version     = PiSdk::Rails::VERSION
  spec.authors     = [ "Your Name" ]
  spec.email       = [ "your.email@example.com" ]
  spec.homepage    = "https://example.com/pi-sdk-rails"
  spec.summary     = "A Rails engine for rapid Pi Network transaction integration."
  spec.description = "This gem abstracts the complexity of Pi network transaction processing for Rails apps."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "https://example.com/gemserver"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://example.com/pi-sdk-rails/source"
  spec.metadata["changelog_uri"] = "https://example.com/pi-sdk-rails/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.1"
  spec.add_development_dependency "appraisal", ">= 2.5.0"
end
