/**
 * PiNetworkBase
 *
 * Framework-agnostic base class for managing Pi Network auth & payments logic.
 *
 * - All state is stored statically, because Pi Browser only allows one session/user at a time.
 * - This class is intended to be mixed in or composed with framework-specific components (React, Stimulus, etc).
 * - Extend and/or override methods as needed.
 */
export default class PiNetworkBase {
  /**
   * Pi Network username object (shared across all instances)
   * @type {object|null}
   */
  static user = null;

  /**
   * Connected status (shared across all instances)
   * @type {boolean}
   */
  static connected = false;

  /**
   * Default payment API path (can be overridden)
   * @type {string}
   */
  static paymentBasePath = 'pi_payment';

  /**
   * Log prefix for all static logs
   * @type {string}
   */
  static logPrefix = '[Pinetwork]';

  /**
   * SDK version
   * @type {string}
   */
  static version = "2.0";

  constructor() {}

  /**
   * Returns the current connection status
   * @returns {boolean}
   */
  static get_connected() { return PiNetworkBase.connected; }

  /**
   * Returns the active user (if any)
   * @returns {object|null}
   */
  static get_user()      { return PiNetworkBase.user; }

  /**
   * Log info details (prefixed)
   * @param {...any} args
   */
  static log(...args)   { console.log(this.logPrefix, ...args); }

  /**
   * Log error details (prefixed)
   * @param {...any} args
   */
  static error(...args) { console.error(this.logPrefix, ...args); }

  /**
   * Initialize the PiNetworkBase instance.
   * Resets user and connected status.
   */
  initializePiNetworkBase() {
    this.user = null;
    this.connected = false;
  }

  /**
   * Authenticate and connect user to Pi Network.
   * Sets PiNetworkBase.connected and user. Calls `onConnection` if present.
   * @async
   * @returns {Promise<void>}
   */
  async connect() {
    if (!window.Pi || typeof window.Pi.init !== "function") {
      PiNetworkBase.error("Pi SDK not loaded.");
      return;
    }
    // Determine Pi.init options based on Rails env
    let piInitOptions = { version: PiNetworkBase.version };
    const railsEnv = (window.RAILS_ENV || process.env?.RAILS_ENV ||
		      process.env?.NODE_ENV || "development");
    if (railsEnv === "development" || railsEnv === "test") {
      piInitOptions.sandbox = true;
    }
    Pi.init(piInitOptions);
    PiNetworkBase.log("SDK initialized", piInitOptions);
    PiNetworkBase.connected = false;
    try {
      const authResponse = await Pi.authenticate(
        ["payments", "username"],
        PiNetworkBase.onIncompletePaymentFound
      );
      PiNetworkBase.accessToken = authResponse.accessToken;
      PiNetworkBase.user = authResponse.user;
      PiNetworkBase.connected = true;
      PiNetworkBase.log("Auth OK", authResponse);
      if (typeof this.onConnection == 'function') {
	// This call is here because developer's Stimulus controller subclassed
	this.onConnection();
      }
    } catch (err) {
      PiNetworkBase.connected = false;
      PiNetworkBase.error("Auth failed", err);
    }
  }

  static async postToServer(path, body) {
    const base = this.paymentBasePath || PiNetworkBase.paymentBasePath;
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

  static async onReadyForServerApproval(paymentId, accessToken) {
    if (!paymentId) {
      PiNetworkBase.error("Approval: missing paymentId");
      return;
    }
    if (!accessToken) {
      PiNetworkBase.error("Approval: missing accessToken");
      return;
    }
    try {
      const data = await PiNetworkBase.postToServer("approve", { paymentId, accessToken });
      PiNetworkBase.log("approve:", data);
    } catch(err) {
      PiNetworkBase.error("approve error", err);
    }
  }

  static async onReadyForServerCompletion(paymentId, transactionId) {
    if (!paymentId || !transactionId) {
      PiNetworkBase.error("Completion: missing ids");
      return;
    }
    try {
      const data = await PiNetworkBase.postToServer("complete", { paymentId, transactionId });
      PiNetworkBase.log("complete:", data);
    } catch(err) {
      PiNetworkBase.error("complete error", err);
    }
  }

  static async onCancel(paymentId) {
    if (!paymentId) {
      PiNetworkBase.error("Cancel: missing paymentId");
      return;
    }
    try {
      const data = await PiNetworkBase.postToServer("cancel", { paymentId });
      PiNetworkBase.log("cancel:", data);
    } catch(err) {
      PiNetworkBase.error("cancel error", err);
    }
  }

  static async onError(error, paymentDTO) {
    const paymentId = paymentDTO?.identifier;
    if (!paymentId || !paymentDTO) {
      PiNetworkBase.error("Error: missing ids", error, paymentDTO);
      return;
    }
    try {
      const data = await PiNetworkBase.postToServer("error", { paymentId, error });
      PiNetworkBase.log("error:", data);
    } catch(err) {
      PiNetworkBase.error("error post", err);
    }
  }

  static async onIncompletePaymentFound(paymentDTO) {
    const paymentId = paymentDTO?.identifier;
    const transactionId = paymentDTO?.transaction?.txid || null;
    if (!paymentId) {
      PiNetworkBase.error("Incomplete: missing paymentId");
      return;
    }
    try {
      const data = await PiNetworkBase.postToServer("incomplete", { paymentId, transactionId });
      PiNetworkBase.log("incomplete:", data);
    } catch(err) {
      PiNetworkBase.error("incomplete post error", err);
    }
  }

  /**
   * Create a new payment request.
   * @param {object} paymentData - Payment details.
   * @param {number} paymentData.amount - Amount in Pi.
   * @param {string} paymentData.memo - Payment memo.
   * @param {object} paymentData.metadata - Optional metadata.
   */
  createPayment(paymentData) {
    if (!PiNetworkBase.connected) {
      PiNetworkBase.error("Not connected to Pi.");
      return;
    }
    const { amount, memo, metadata } = paymentData || {};
    if (typeof amount !== 'number' ||
	!memo || typeof memo !== 'string' ||
	!metadata || typeof metadata !== 'object' || Object.keys(metadata).length === 0) {
      PiNetworkBase.error("Invalid paymentData", paymentData);
      return;
    }

    const onReadyForServerApproval = (paymentId) => {
      PiNetworkBase.onReadyForServerApproval(paymentId, PiNetworkBase.accessToken);
    }
    Pi.createPayment(
      paymentData,
      {
	"onReadyForServerApproval": onReadyForServerApproval,
	"onReadyForServerCompletion": PiNetworkBase.onReadyForServerCompletion,
	"onCancel": PiNetworkBase.onCancel,
	"onError": PiNetworkBase.onError,
	"onIncompletePaymentFound": PiNetworkBase.onIncompletePaymentFound
      }
    );
  }
}
