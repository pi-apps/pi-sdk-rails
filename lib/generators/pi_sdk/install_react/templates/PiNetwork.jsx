// ============================================================================
// Example PiNetwork React Component
//
// For host app developers: This is a ready-to-use or extendable Pi Network
// integration component. It composes with PiNetworkBase for Pi SDK connection
// and payment flows. Recommended as a starting entry in your React app.
// Modify to add new UI, callbacks, props, etc, as you require.
// Place <div id="pinetwork"></div> in your HTML and mount in index.jsx.
// ============================================================================
import React from 'react';
import PiNetworkBase from "./pi_network_base";

export default class PiNetwork extends React.Component {
  constructor(props) {
    super(props);
    // Defensive mixin binding: allows PiNetworkBase prototype methods to be used
    Object.getOwnPropertyNames(PiNetworkBase.prototype).forEach(name => {
      if (name !== 'constructor') {
        this[name] = PiNetworkBase.prototype[name].bind(this);
      }
    });
    this.initializePiNetworkBase();
    this.state = {
      connected: PiNetworkBase.connected
    };
  }

  componentDidMount() {
    // Connection to Pi SDK happens on mount
    this.connect();
  }

  // Called when connection state changes (e.g., on successful auth)
  onConnection() {
    this.setState({ connected: PiNetworkBase.connected });
  }

  // Example payment initiation (customize as needed)
  buy() {
    PiNetworkBase.log("Buy Initiated");
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
    return <div>
      {/* Main Pi Network Widget UI below */}
      Welcome to PiNetwork!
      <button
        disabled={!this.state.connected}
        onClick={() => this.buy()}
      >Buy</button>
    </div>;
  }
}

// Allow direct use of PiNetworkBase methods on this component
Object.assign(PiNetwork.prototype, PiNetworkBase.prototype);
