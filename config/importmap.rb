# pin "pi-sdk", to: "https://sdk.minepi.com/pi-sdk.js", preload: true

# Pin all engine-provided Stimulus controllers for sharing with host apps
pin_all_from File.expand_path("../app/javascript/pi_sdk/controllers", __dir__),
             under: "pi_sdk", to: "pi_sdk/controllers"
