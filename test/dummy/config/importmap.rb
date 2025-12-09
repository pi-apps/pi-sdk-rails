# Pin main entrypoints
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Pin all local (dummy app) controllers
pin_all_from "app/javascript/controllers", under: "controllers"

# Pin all engine controllers for subclassing/extension etc.
pin_all_from "../../app/javascript/pinetwork/rails/controllers", under: "pinetwork/controllers"

# (Optional: Overlay) If you have a dummy-local version you want to always use
pin "controllers/pinetwork_controller", to: "controllers/pinetwork_controller.js"
