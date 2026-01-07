// @EnginePiSdkController.js - EnginePiSdkController
// Subclass this Stimulus controller in your host app to customize Pi payment lifecycle integration.
//
// == Customization Guide ==
// In your host app's app/javascript/controllersPiSdkController.js:
//
//   import EnginePiSdkController from 'EnginePiSdkController'
//   export default class extends EnginePiSdkController {
//     // Optionally override callbacks like onConnection here.
//   }
//
// This controller mixes in PiSdkBase for all Pi protocol logic (connect, buy, etc.)
//
import { Controller } from "@hotwired/stimulus"
import { PiSdkBase } from "pi_sdk/pi-sdk-js"

export default class EnginePiSdkController extends Controller {
  constructor(...args) {
    super(...args);
    this._piSdk = new PiSdkBase();
    // Mixin protocol public methods for direct use (by name)
    Object.getOwnPropertyNames(PiSdkBase.prototype).forEach(name => {
      if (name !== 'constructor' && typeof this[name] === 'undefined') {
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
    console.log("Calling pisdk connect before");
    if (typeof this._piSdk.connect === 'function') {
      console.log("Calling pisdk connect");
      this._piSdk.connect();
    }
    if (super.connect) super.connect();
  }

  // Overridable example callback hook
  onConnection() {
    console.log("Engine onConnection");
    // Host-app logic upon connection
  }

  // Expose SDK static state as controller getters
  get accessToken() {
    return PiSdkBase.accessToken;
  }
  /**
   * @returns {import('pi-sdk-js').PiUser|null}
   */
  get user() {
    return PiSdkBase.user;
  }

  /**
   * Returns true if the user is currently connected via the underlying PiSdkBase
   * @returns {boolean}
   */
  is_connected() {
    return PiSdkBase.connected;
  }
  // You may override or extend more engine, protocol, or UI methods as needed.
}
