/**
 * App Pi SDK Stimulus Controller
 *
 * HOW TO CUSTOMIZE:
 * - Subclass this controller to override the Pi payment flow. Place this in your app/javascript/controllers directory.
 * - Override static methods to customize what happens for Pi SDK payment events (see examples below).
 * - Instance methods handle UI and user triggers (connect/onConnection/buy, etc).
 * - Use createPayment(paymentData) to initiate payments via Pi SDK.
 *
 * STATIC CALLBACK SIGNATURES (triggered by Pi SDK):
 *   static onReadyForServerApproval(paymentId, accessToken)       // Payment created
 *   static onReadyForServerCompletion(paymentId, transactionId)   // Payment completed
 *   static onCancel(paymentId)                                    // Payment cancelled by user
 *   static onError(error, paymentDTO)                             // Error occurred
 *   static onIncompletePaymentFound(paymentDTO)                   // Incomplete payment found on new session
 *
 * For paymentData and event argument details, see the engine docs or pisdk_controller.js in the engine source.
 *
 * Stimulus targets: ["buyButton"] (to enable/disable payment button)
 */
import EnginePiSdkController from "pi_sdk/EnginePiSdkController"

export default class PiSdkController extends EnginePiSdkController {
  // Demo purposes, random user id
  static demoUserId = Math.floor(10000 + Math.random() * 90000);
  // --- Pi SDK Callbacks ---

  /**
   * Example presumes the existence of a buyButton that is initially disabled until
   * user authentication completes satisfactorily
   **/
  static targets = ["buyButton"];

  /**
   * Enable the payment button (called after Pi authenticated)
   */
  enableButton() {
    if (this.hasBuyButtonTarget) {
      this.buyButtonTarget.disabled = false;
    }
  }

  /**
   * Called by engine after Pi is authenticated and connected
   * (you can override this to set UI state, etc)
   */
  onConnection() {
    this.enableButton();
    // Any local enhancements or overrides
    PiSdkController.log("Local (host) controller connected after engine base");
  }

  /**
   * Example action: Initiate a Pi payment.
   * Override or call with your real payment data as needed.
   * Calls `createPayment(paymentData)` inherited from engine.
   */
  buy() {
    PiSdkController.log("Buy Initiated");
    // Demo purposes, random order id
    const demoOrderId = Math.floor(10000 + Math.random() * 90000);
    const paymentData = {
      amount: 0.01,                 /* Pi Amount being Transacted */
      memo: "ConnecTo-Pi Admission",  /* Arbitrary payment memo */
      /* Arbitrary metadata */
      metadata: { description: "ConnecTo Admission",
		  /* order_id should match your PiTransaction field name */
		  order_id: demoOrderId }
    };
    this.createPayment(paymentData);
  }

  // DRY log helpers for consistency and subclass safety
  static logPrefix = '[PiSdk]';
  static log(...args) {
    console.log(this.logPrefix, ...args);
  }
  static error(...args) {
    console.error(this.logPrefix, ...args);
  }
}
