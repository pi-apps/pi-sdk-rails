require "rails/generators/base"

module Pinetwork
  module Rails
    module Install
      class ImportmapGenerator < ::Rails::Generators::Base
        source_root File.expand_path("../../../../..", __dir__)
        desc "Copies pinetwork-rails importmap.rb to host app"

        def copy_importmap
          copy_file "config/importmap.rb", "config/importmap.pinetwork-rails.rb"
          say_status :info, "Added pi-sdk importmap pin (Pi Network JS SDK) in config/importmap.pinetwork-rails.rb"
          say_status :note, "Manually merge any custom pins into config/importmap.rb in the host app. Do not overwrite non-engine pins."
        end
      end
    end
  end
end
