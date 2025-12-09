// @pi_network_controller.js - EnginePinetworkController
// Subclass this Stimulus controller in your host app to customize Pi payment lifecycle integration.
//
// == Customization Guide ==
//
// To customize the Pi Network payment integration, create a subclass in your app (e.g. `PinetworkController`):
//
//   import { EnginePinetworkController } from 'pinetwork/controllers/pinetwork_controller'
//   export default class PinetworkController extends EnginePinetworkController {
//     // Optional: override to react to successful SDK connection
//     onConnection() {
//       // Your custom code here...
//     }
//   }
//
// You can override any non-static method here (such as `onConnection`) in your own controller.
// Route all callbacks (for onReadyForServerApproval, etc) to your Rails API, or customize behavior by subclassing the static methods.
//
// == End Customization Guide ==

import { Controller } from "@hotwired/stimulus"

export class EnginePinetworkController extends Controller {
  static paymentBasePath = 'pi_payment';   // App can override by subclassing
  static accessToken = null; // Store after authenticate for static callbacks
  static logPrefix = '[Pinetwork]';
  static log(...args) {
    console.log(this.logPrefix, ...args);
  }
  static error(...args) {
    console.error(this.logPrefix, ...args);
  }
  user = null;
  connected = false;

  /**
   * Called automatically when the Stimulus controller connects.
   * Override in your subclass to react to successful auth connection.
   */
  onConnection() {}

  /**
   * DRY helper for posting JSON to the Rails backend.
   * @param {string} path Relative path, e.g. 'approve'
   * @param {object} body Request payload
   * @returns {Promise<object>} Parsed JSON response
   */
  static async postToServer(path, body) {
    const base = this.paymentBasePath || EnginePinetworkController.paymentBasePath;
    const resp = await fetch(`${base}/${path}`, {
      method: "POST",
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(body)
    });
    return resp.json();
  }

  async connect() {
    if (!window.Pi || typeof window.Pi.init !== "function") {
      this.constructor.error("Pi SDK not loaded.");
      return;
    }
    // Determine Pi.init options based on Rails env
    let piInitOptions = { version: "2.0" };
    const railsEnv = (window.RAILS_ENV || process.env?.RAILS_ENV || process.env?.NODE_ENV || "development");
    if (railsEnv === "development" || railsEnv === "test") {
      piInitOptions.sandbox = true;
    }
    Pi.init(piInitOptions);
    this.constructor.log("SDK initialized", piInitOptions);

    try {
      const authResponse = await Pi.authenticate(
        ["payments", "username"],
        EnginePinetworkController.onIncompletePaymentFound
      );
      this.accessToken = authResponse.accessToken;
      this.user = authResponse.user;
      this.connected = true;
      this.constructor.log("Auth OK", authResponse);
      this.onConnection();
    } catch (err) {
      this.connected = false;
      this.constructor.error("Auth failed", err);
    }
  }

  static async onReadyForServerApproval(paymentId, accessToken) {
    if (!paymentId) {
      EnginePinetworkController.error("Approval: missing paymentId");
      return;
    }
    if (!accessToken) {
      EnginePinetworkController.error("Approval: missing accessToken");
      return;
    }
    try {
      const data = await EnginePinetworkController.postToServer("approve", { paymentId, accessToken });
      EnginePinetworkController.log("approve:", data);
    } catch(err) {
      EnginePinetworkController.error("approve error", err);
    }
  }

  static async onReadyForServerCompletion(paymentId, transactionId) {
    if (!paymentId || !transactionId) {
      EnginePinetworkController.error("Completion: missing ids");
      return;
    }
    try {
      const data = await EnginePinetworkController.postToServer("complete", { paymentId, transactionId });
      EnginePinetworkController.log("complete:", data);
    } catch(err) {
      EnginePinetworkController.error("complete error", err);
    }
  }

  static async onCancel(paymentId) {
    if (!paymentId) {
      EnginePinetworkController.error("Cancel: missing paymentId");
      return;
    }
    try {
      const data = await EnginePinetworkController.postToServer("cancel", { paymentId });
      EnginePinetworkController.log("cancel:", data);
    } catch(err) {
      EnginePinetworkController.error("cancel error", err);
    }
  }

  static async onError(error, paymentDTO) {
    const paymentId = paymentDTO?.identifier;
    if (!paymentId || !paymentDTO) {
      EnginePinetworkController.error("Error: missing ids", error, paymentDTO);
      return;
    }
    try {
      const data = await EnginePinetworkController.postToServer("error", { paymentId, error });
      EnginePinetworkController.log("error:", data);
    } catch(err) {
      EnginePinetworkController.error("error post", err);
    }
  }

  static async onIncompletePaymentFound(paymentDTO) {
    const paymentId = paymentDTO?.identifier;
    const transactionId = paymentDTO?.transaction?.txid || null;
    if (!paymentId) {
      EnginePinetworkController.error("Incomplete: missing paymentId");
      return;
    }
    try {
      const data = await EnginePinetworkController.postToServer("incomplete", { paymentId, transactionId });
      EnginePinetworkController.log("incomplete:", data);
    } catch(err) {
      EnginePinetworkController.error("incomplete post error", err);
    }
  }

  /**
   * Initiate a Pi payment flow through the SDK.
   * @param paymentData { amount: number, memo: string, metadata: object }
   */
  createPayment(paymentData) {
    if (!this.connected) {
      this.constructor.error("Not connected to Pi.");
      return;
    }
    const { amount, memo, metadata } = paymentData || {};
    if (typeof amount !== 'number' ||
	!memo || typeof memo !== 'string' ||
	!metadata || typeof metadata !== 'object' || Object.keys(metadata).length === 0) {
      this.constructor.error("Invalid paymentData", paymentData);
      return;
    }

    const onReadyForServerApproval = (paymentId) => {
      EnginePinetworkController.onReadyForServerApproval(paymentId, this.accessToken);
    }
    Pi.createPayment(
      paymentData,
      {
	"onReadyForServerApproval": onReadyForServerApproval,
	"onReadyForServerCompletion": EnginePinetworkController.onReadyForServerCompletion,
	"onCancel": EnginePinetworkController.onCancel,
	"onError": EnginePinetworkController.onError,
	"onIncompletePaymentFound": EnginePinetworkController.onIncompletePaymentFound
      }
    );
  }
}
