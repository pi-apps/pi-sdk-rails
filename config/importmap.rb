# pin "pi-sdk", to: "https://sdk.minepi.com/pi-sdk.js", preload: true

# Pin all engine-provided Stimulus controllers for sharing with host apps
pin_all_from File.expand_path("../app/javascript/pinetwork/rails/controllers", __dir__),
             under: "pinetwork", to: "pinetwork/rails/controllers"
