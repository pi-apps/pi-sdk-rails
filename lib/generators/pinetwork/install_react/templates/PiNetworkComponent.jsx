// ============================================================================
// PiNetworkComponent.jsx - Reusable Pi Network base React component
// For host app developers: use as a compositional base for advanced or custom
// Pi Network-enabled React UIs. Extends PiNetworkBase and provides basic auth
// and connection-to-Pi logic. Add your additional UI, props, methods as needed.
// Consider extending or wrapping for advanced payment behaviors or multi-step UIs.
// ============================================================================
import React from 'react';
import PiNetworkBase from "./pi_network_base";

export default class PiNetworkComponent extends React.Component {
  constructor(props) {
    super(props);
    // Defensive mixin binding for underlying SDK logic
    Object.getOwnPropertyNames(PiNetworkBase.prototype).forEach(name => {
      if (name !== 'constructor') {
        this[name] = PiNetworkBase.prototype[name].bind(this);
      }
    });
    this.initializePiNetworkBase();
  }
  componentDidMount() {
    // Connect to Pi Browser/session on mount
    this.connect();
  }
  // Utility: can be used in your custom render to check connection
  is_connected_to_pi() {
    return PiNetworkBase.connected;
  }
}

// Make all PiNetworkBase methods available to extending classes
Object.assign(PiNetworkComponent.prototype, PiNetworkBase.prototype);
