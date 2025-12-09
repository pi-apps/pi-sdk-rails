import { EnginePinetworkController } from "pinetwork/pinetwork_controller"

export default class extends EnginePinetworkController {
  static onReadyForServerApproval(...args) { super.onReadyForServerApproval(...args); } // or real logic
  static onReadyForServerCompletion(...args) { super.onReadyForServerCompletion(...args); }
  static onCancel(...args) { super.onCancel(...args); }
  static onError(...args) { super.onError(...args); }
  static onIncompletePaymentFound(...args) { super.onIncompletePaymentFound(...args); }

  static targets = ["buyButton"]

  enableButton() {
    if (this.hasBuyButtonTarget) {
      this.buyButtonTarget.disabled = false;
    }
  }

  connect() {
    super.connect();
  }

  onConnection() {
    this.enableButton();
    // Any local enhancements or overrides
    console.log("Local (host) controller connected after engine base");
  }

  buy() {
    console.log("Buy Initiated")
    const paymentData = {
      amount: 0.01,  /* Pi Amount being Transacted */
      memo: "ConnecTo-Pi Admission", /* "Any information that you want to add to payment" */
      metadata: { description: "ConnecTo Admission" }, /* { Special Information: 1234, ... } */
    };
    this.createPayment(paymentData);
  }
}
