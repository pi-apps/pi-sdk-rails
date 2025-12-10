// ============================================================================
// Example PiSdk React Component
//
// For host app developers: This is a ready-to-use or extendable Pi Sdk
// integration component. It composes with PiSdkBase for Pi SDK connection
// and payment flows. Recommended as a starting entry in your React app.
// Modify to add new UI, callbacks, props, etc, as you require.
// Place <div id="pisdk"></div> in your HTML and mount in index.jsx.
// ============================================================================
import React from 'react';
import PiSdkBase from "./pi_sdk_base";

export default class PiButton extends React.Component {
  constructor(props) {
    super(props);
    // Defensive mixin binding: allows PiSdkBase prototype methods to be used
    Object.getOwnPropertyNames(PiSdkBase.prototype).forEach(name => {
      if (name !== 'constructor') {
        this[name] = PiSdkBase.prototype[name].bind(this);
      }
    });
    this.initializePiSdkBase();
    this.state = {
      connected: PiSdkBase.connected
    };
  }

  componentDidMount() {
    // Connection to Pi SDK happens on mount
    this.connect();
  }

  // Called when connection state changes (e.g., on successful auth)
  onConnection() {
    this.setState({ connected: PiSdkBase.connected });
  }

  // Example payment initiation (customize as needed)
  buy() {
    PiSdkBase.log("Buy Initiated");
    // For real apps replace with your order id and payment data
    const demoOrderId = Math.floor(10000 + Math.random() * 90000);
    const paymentData = {
      amount: 0.01,
      memo: "ConnecTo-Pi Admission",
      metadata: { description: "ConnecTo Admission", order_id: demoOrderId }
    };
    this.createPayment(paymentData);
  }

  render() {
    // You can replace this UI with a real checkout or other interactions
    return(<button
        disabled={!this.state.connected}
        onClick={() => this.buy()}
      >Buy</button>);
  }
}

// Allow direct use of PiSdkBase methods on this component
Object.assign(PiButton.prototype, PiSdkBase.prototype);
