# Only require importmap-rails if available
begin
  require "importmap-rails"
rescue LoadError
  # importmap-rails is not installed; that's okay for jsbundling/React setups
end

require_relative 'routing_extensions'

module PiSdk
  class << self
    attr_accessor :importmap
  end
  class Engine < ::Rails::Engine
    isolate_namespace PiSdk

    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "pi-sdk-rails.routing_extensions" do
      ActionDispatch::Routing::Mapper.include PiSdk::RoutingExtensions
    end

    initializer "pi-sdk-rails.importmap", before: "importmap" do |app|
      # Only touch importmap if available
      if defined?(Importmap) &&
         app.config.respond_to?(:importmap) &&
         app.config.importmap.respond_to?(:paths)
        app.config.assets.paths << Engine.root.join("app/javascript")
        app.config.importmap.paths << Engine.root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << root.join("app/assets/javascripts")
      end
    end
  end
end
