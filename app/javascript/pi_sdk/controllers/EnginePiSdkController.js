// @pi_sdk_controller.js - EnginePiSdkController
// Subclass this Stimulus controller in your host app to customize Pi payment lifecycle integration.
//
// == Customization Guide ==
// In your host app's app/javascript/controllers/pi_sdk_controller.js:
//
//   import EnginePiSdkController from 'engine_pi_sdk_controller'
//   export default class extends EnginePiSdkController {
//     // Optionally override callbacks like onConnection here.
//   }
//
// This controller mixes in PiSdkBase for all Pi protocol logic (connect, buy, etc.)
//
import { Controller } from "@hotwired/stimulus"
import PiSdkBase from "pi_sdk/PiSdkBase"

console.log("EnginePiSdkController loading");
export default class EnginePiSdkController extends Controller {
  constructor(...args) {
    super(...args);
    this._piSdk = new PiSdkBase();
    // Mixin protocol public methods for direct use (by name)
    Object.getOwnPropertyNames(PiSdkBase.prototype).forEach(name => {
      if (name !== 'constructor') {
        this[name] = this._piSdk[name].bind(this._piSdk);
      }
    });
    const HOST_CALLBACKS = [
      "onConnection",
      // Extend this list with other callback points as needed
      // "onReadyForServerApproval", "onError", etc.
    ];
    HOST_CALLBACKS.forEach(name => {
      if (typeof this[name] === "function") {
        this._piSdk[name] = this[name].bind(this);
      }
    });
  }

  connect() {
    // Optionally perform setup or connection logic
    if (typeof this._piSdk.connect === 'function') {
      this._piSdk.connect();
    }
    if (super.connect) super.connect();
  }

  // Overridable example callback hook
  onConnection() {
    console.log("Engine onConnection");
    // Host-app logic upon connection
  }

  // You may override or extend more engine, protocol, or UI methods as needed.
}
