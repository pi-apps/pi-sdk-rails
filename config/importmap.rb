# pin "pi-sdk", to: "https://sdk.minepi.com/pi-sdk.js", preload: true

pin "async-mutex", to: "https://cdn.jsdelivr.net/npm/async-mutex@0.4.0/+esm"

# Pin all engine-provided Stimulus controllers for sharing with host apps
pin_all_from File.expand_path("../app/javascript/pi_sdk/controllers", __dir__),
             under: "pi_sdk", to: "pi_sdk/controllers"
